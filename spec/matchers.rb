require 'rspec/expectations'

module WinRMSpecs
  def self.stdout(output)
    output[:data].collect do |i|
      i[:stdout]
    end.join('\r\n').gsub(/(\\r\\n)+$/, '')
  end

  def self.stderr(output)
    output[:data].collect do |i|
      i[:stderr]
    end.join('\r\n').gsub(/(\\r\\n)+$/, '')
  end
end

RSpec::Matchers.define :have_stdout_match do |expected_stdout|
  match do |actual_output|
    expected_stdout.match(WinRMSpecs.stdout(actual_output)) != nil
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stdout(actual_output)}' would match #{expected_stdout}"
  end
end

RSpec::Matchers.define :have_stderr_match do |expected_stderr|
  match do |actual_output|
    expected_stderr.match(WinRMSpecs.stderr(actual_output)) != nil
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stderr(actual_output)}' would match #{expected_stderr}"
  end
end

RSpec::Matchers.define :have_no_stdout do
  match do |actual_output|
    stdout = WinRMSpecs.stdout(actual_output)
    stdout == '\r\n' || stdout == ''
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stdout(actual_output)}' would have no stdout"
  end
end

RSpec::Matchers.define :have_no_stderr do
  match do |actual_output|
    stderr = WinRMSpecs.stderr(actual_output)
    stderr == '\r\n' || stderr == ''
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stderr(actual_output)}' would have no stderr"
  end
end

RSpec::Matchers.define :have_exit_code do |expected_exit_code|
  match do |actual_output|
    expected_exit_code == actual_output[:exitcode]
  end
  failure_message do |actual_output|
    "expected exit code #{expected_exit_code}, but got #{actual_output[:exitcode]}"
  end
end
