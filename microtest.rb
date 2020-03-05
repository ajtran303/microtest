# # Code-along from Ryan Davis "Writing a Test Framework from Scratch" talk at RailsConf2016
# # https://www.youtube.com/watch?v=VPr5pmlAq20
#
# # assert takes the result of an expression and fails if that result is not truthy
# # raise == stop, fail == full stop
# # raise allows to spec what exception to use and the backtrace to show in stdout
# # caller for backtrace returns where in the call stack @ runtime the error occured
#
# def assert test, msg = "Failed test"
#   unless test then
#     bt = caller.drop_while { |s| s =~/#{__FILE__}/ }
#     raise RuntimeError, msg, bt
#   end
# end
#
# assert 1 == 1
# # assert 1 == 2
#
# # this
#
# def assert_equal a, b
#   assert a == b, "Failed assert_equal #{a} vs #{b}"
# end
#
# assert_equal 1, 1
# # assert_equal 1, 2
#
# # Never ever test floats for equality
# # This checks to see if two floats are close enough
# def assert_in_delta a, b
#   assert (a-b).abs <= 0.001, "Failed assert_in_delta #{a} vs #{b}"
# end
#
# assert_in_delta 0.001, 0.002
# assert_in_delta 0.001, 0.005

# how do we write a test?
# def test name="untitled"
#   yield
# end

# tests need to always
# pass regardless of
# what was run, what order they were run in
# or anything else!
# keep tests separated by methods
# wrap tests in a class
# instantiate a new class before calling the method
# a run instance method can make tests run itself
# # see code snippet below -
# run instance methods can also allow extend testing to setup/teardown features

# class XTest
#   def self.run
#     # public_instance_methods returns an array of all the public_instance_methods on a class or module
#     # enumerable's grep method filters on methods that end in _test
#     public_instance_methods.grep(/_test$/).each do |name|
#       self.new.run name
#     end
#   end
#
#   # def run...
#   # ...test methods...
# end
# # wrap in class method instantiates and runs each test

class Test
  attr_accessor :name
  attr_accessor :failure
  alias failure? failure

  def initialize name
    self.name = name
    self.failure = false
  end
  # 17 mins autorun

  TESTS = [] # record what we need to run

  def self.inherited x
    TESTS << x # record all the tests of the subclasses
  end


  # Test.run_all_tests - only run test classes
  # Test.run - each class runs their indv tests
  # Test#run - each class instance runs a single test AND handles any failures

  def self.run_all_tests
    reporter = Reporter.new

    TESTS.each do |klass|
      klass.run reporter # ennumerate the collection and run the tests
    end

    reporter.summary
  end

  # suggests to put in own file, microtest/autorun
  # ie. require "microtest/autorun"

  # time stamp at 20:50 to start refactoring everything omg

  def self.test_names # generate all the tests to run
    public_instance_methods.grep(/_test$/)
  end

  def self.run reporter # test class run
    test_names.shuffle.each do |name| # ennumerate over tests to run, randomly
      reporter << self.new(name).run # pass name to initializer, not to run method
    end
  end

  def run # test instance run
    send name
  rescue => e
    self.failure = e # record exception in failure
  ensure
    return self # return the test instance (instead of exception)
  end

  # Assertions
  def assert test, msg = "Failed test"
    unless test then
      bt = caller.drop_while { |s| s =~/#{__FILE__}/ }
      raise RuntimeError, msg, bt
    end
  end

  def assert_equal a, b
    assert a == b, "Failed assert_equal #{a} vs #{b}"
  end

  def assert_in_delta a, b
    assert (a-b).abs <= 0.001, "Failed assert_in_delta #{a} vs #{b}"
  end

  def test(description = "")
    puts "#{description}: "
    yield
  end
end


class Reporter # timestamp 22:58 refactoring
  attr_accessor :failures

  def initialize
    self.failures = []
  end

  def << result
    # conditional for exception handling
    unless result.failure? then
      print "." # print a dot for each test run
    else
      print "F"
      failures << result
    end
  end

  def summary
    puts

    failures.each do |result|
      failure = result.failure
      puts
      puts "Failure: #{result.class}##{result.name}: #{failure.message}" # where is .message ???
      puts "  #{failure.backtrace.first}"
    end
  end

end

class XTest < Test
  def add_2_and_2_equal_5_test
    assert_equal 2+2, 5
  end
end

class TestAssertions < Test
  def test_assert_test
    assert false
  end

  def test_assert_bad_test
    assert true
  end

  def test_assert_equal_test
    assert_equal 5, 2+2
  end

  def test_assert_equal_bad_test
    assert_equal 5, 2+2
  end

  def test_assert_in_delta_test
    assert_in_delta 0.0001, 0.0002
  end

  def test_assert_in_delta_bad_test
    assert_in_delta 0.5, 0.6
  end
end

Test.run_all_tests


# Then make your tests a subclass of the Test class
# class WhateverTest < Test
# # ... test methods...
# # test method names need to end in _test
# Test.run_all_tests
# end
