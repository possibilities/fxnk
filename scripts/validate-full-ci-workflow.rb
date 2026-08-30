#!/usr/bin/env ruby

require "psych"

class ContractError < StandardError
end

def fail_contract(message)
  raise ContractError, message
end

def mapping_pairs(node, label)
  fail_contract("#{label} must be a mapping") unless node.is_a?(Psych::Nodes::Mapping)

  pairs = {}
  node.children.each_slice(2) do |key_node, value_node|
    fail_contract("#{label} has a non-scalar key") unless key_node.is_a?(Psych::Nodes::Scalar)
    key = key_node.value
    fail_contract("#{label} has duplicate key #{key.inspect}") if pairs.key?(key)
    fail_contract("#{label} uses a YAML merge key") if key == "<<"
    pairs[key] = [key_node, value_node]
  end
  pairs
end

def require_keys(pairs, expected, label)
  actual = pairs.keys.sort
  wanted = expected.sort
  fail_contract("#{label} keys are #{actual.inspect}, expected #{wanted.inspect}") \
    unless actual == wanted
end

def require_plain_key(key_node, expected, label)
  valid = key_node.value == expected && key_node.plain && !key_node.quoted &&
    key_node.tag.nil? && key_node.anchor.nil?
  fail_contract("#{label} key must use the plain #{expected}: form") unless valid
end

def require_plain_scalar(node, expected, label)
  valid = node.is_a?(Psych::Nodes::Scalar) && node.value == expected &&
    node.plain && !node.quoted && node.tag.nil? && node.anchor.nil?
  fail_contract("#{label} must be the plain scalar #{expected.inspect}") unless valid
end

def require_empty_scalar(node, label)
  require_plain_scalar(node, "", label)
end

def require_singleton_sequence(node, expected, label)
  fail_contract("#{label} must be a sequence") unless node.is_a?(Psych::Nodes::Sequence)
  fail_contract("#{label} must contain exactly one entry") unless node.children.length == 1
  require_plain_scalar(node.children.first, expected, "#{label} entry")
end

def validate_on(node, branch_key, branch, label)
  on_pairs = mapping_pairs(node, "#{label} on")
  require_keys(on_pairs, ["workflow_dispatch", "push"], "#{label} on")
  on_pairs.each { |key, (key_node, _)| require_plain_key(key_node, key, "#{label} on") }
  require_empty_scalar(on_pairs.fetch("workflow_dispatch").last,
    "#{label} workflow_dispatch")

  push_pairs = mapping_pairs(on_pairs.fetch("push").last, "#{label} push")
  require_keys(push_pairs, [branch_key], "#{label} push")
  branch_key_node, branches_node = push_pairs.fetch(branch_key)
  require_plain_key(branch_key_node, branch_key, "#{label} push")
  require_singleton_sequence(branches_node, branch, "#{label} #{branch_key}")
end

def validate_concurrency(node)
  pairs = mapping_pairs(node, "hosted concurrency")
  require_keys(pairs, ["group", "cancel-in-progress"], "hosted concurrency")
  pairs.each { |key, (key_node, _)| require_plain_key(key_node, key, "hosted concurrency") }
  require_plain_scalar(pairs.fetch("group").last, "full-ci", "hosted concurrency group")
  require_plain_scalar(pairs.fetch("cancel-in-progress").last, "true",
    "hosted concurrency cancellation")
end

begin
  mode = ARGV.shift
  fail_contract("usage: validate-full-ci-workflow.rb hosted|main") \
    unless ["hosted", "main"].include?(mode) && ARGV.empty?

  stream = Psych.parse_stream($stdin.read)
  fail_contract("workflow must contain exactly one YAML document") \
    unless stream.children.length == 1
  root = stream.children.first.root
  top = mapping_pairs(root, "workflow root")

  on_entry = top["on"]
  fail_contract("workflow root is missing on") unless on_entry
  require_plain_key(on_entry.first, "on", "workflow root")

  if mode == "hosted"
    validate_on(on_entry.last, "branches", "integration", "hosted")
    concurrency_entry = top["concurrency"]
    fail_contract("workflow root is missing concurrency") unless concurrency_entry
    require_plain_key(concurrency_entry.first, "concurrency", "workflow root")
    validate_concurrency(concurrency_entry.last)
  else
    validate_on(on_entry.last, "branches-ignore", "main", "main")
  end
rescue Psych::SyntaxError, ContractError => error
  warn "validate-full-ci-workflow: #{error.message}"
  exit 1
end
