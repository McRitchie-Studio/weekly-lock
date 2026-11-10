# frozen_string_literal: true

# WHAT KEEPS scan_ruby HONEST.
#
# Until 2026-11, bin/brakeman forced --ensure-latest. When brakeman 8.1.0 was
# released, brakeman 8.0.6 exited 5 ("not the latest version") with no code
# change. The scan_ruby job stopped at that step, so bin/bundler-audit never ran
# and 65 gem advisories stayed hidden. This file checks that the lane fails only
# on a finding, and that it still runs both scanners.
#
# Run directly:
#   bin/rails test test/lib/ci_scan_lanes_test.rb

require "test_helper"
require "yaml"

class CiScanLanesTest < ActiveSupport::TestCase
  ROOT = Rails.root
  CI = YAML.safe_load_file(ROOT.join(".github/workflows/ci.yml"), aliases: true)

  # Match the code, not the comments: the binstub names the flag it dropped.
  def brakeman_code
    ROOT.join("bin/brakeman").read.lines.reject { |l| l.strip.start_with?("#") }.join
  end

  def runs_of(job)
    CI.fetch("jobs").fetch(job).fetch("steps").filter_map { |s| s["run"] }.join("\n")
  end

  test "bin/brakeman does not force --ensure-latest" do
    refute_match(/--ensure-latest/, brakeman_code,
                 "--ensure-latest makes brakeman exit 5 on brakeman's release cadence, " \
                 "not on a finding. Upgrade brakeman through Gemfile.lock instead.")
  end

  test "bin/brakeman still exits nonzero on a finding" do
    refute_match(/--no-exit-on-warn/, brakeman_code,
                 "that flag makes scan_ruby green for every future warning")
  end

  test "scan_ruby runs brakeman and bundler-audit" do
    runs = runs_of("scan_ruby")
    assert_match(%r{bin/brakeman}, runs)
    assert_match(%r{bin/bundler-audit}, runs)
  end

  # An advisory is silenced only on Alex McRitchie's ruling. The stock Rails
  # placeholder is the only entry allowed until then.
  test "bundler-audit ignores no real advisory" do
    ignored = Array(YAML.safe_load_file(ROOT.join("config/bundler-audit.yml"))["ignore"])
    real = ignored.grep(/\A(CVE-\d|GHSA-)/)
    assert_empty real, "advisories ignored without a ruling: #{real.join(', ')}"
  end
end
