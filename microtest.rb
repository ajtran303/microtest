# TODO
# Separate auto-run into own module?
# Add some more assertions
# Ditto assertions?

class MicroTest

  attr_accessor :name, :failure
  alias failure? failure

  def initialize(name)
    self.name = name
    self.failure = false
  end

  TESTS = []

  # record test methods from subclasses in array
  def self.inherited(subclass_tests)
    TESTS << subclass_tests
  end

  # call MicroTest.run_all_tests to auto-run every test and report on them
  # at the class level (?)
  def self.run_all_tests

    # instantiate new Reporter
    reporter = Reporter.new

    # and pass it to the run method
    # to have it report on every test
    TESTS.each do |klass|
      klass.run(reporter)
    end

    reporter.summary
  end

  # ennumerate over all method names ending in _test
  def self.test_names
    public_instance_methods.grep(/_test$/)
  end

  # running tests at class level
  # ie. each class runs its indv tests
  def self.run(reporter)
    # ennumerate over tests to run, randomly
    test_names.shuffle.each do |name|
      # when this run method is called with name passed to initializer
      # all this is the (result) argument for the reporter shovel method
      # ie. def << (result)
      reporter << (self.new(name).run)
    end
  end

  # run tests at instance level
  # ie. each class instance runs its indv test and handles its failures
  def run
    send name # what does send do?
  rescue => e # look for exceptions
    self.failure = e # store in failure attr
  ensure
    return self # return the test instance
  end

  # Assertions

  # Basic assert method takes a test arg and an error message arg
  # if falsy, will raise a runtime error with message
  # the backtrace caller specifies a pretty message based on where the error occured

  def assert(test, msg = "Failed test")
    unless test then
      bt = caller.drop_while { |s| s =~/#{__FILE__}/ }
      raise RuntimeError, msg, bt
    end
  end

  # uses is equal to operator
  def assert_equal(a, b)
    assert(a == b, "Failed assert_equal #{a} vs #{b}")
  end

  # for floats within one one-thousandth of each other
  def assert_in_delta(a, b)
    assert( ((a-b).abs <= 0.001), "Failed assert_in_delta #{a} vs #{b}")
  end

  # for custom tests?
  # how to use yield?
  # commented out - doesn't break code

  # def test(description = "")
  #   puts "#{description}: "
  #   yield
  # end

end

# Reporter class handles stdout messages
# Instantiated in run_all_tests method
# prints . dot for each passed test
# and F for every failure
class Reporter
  attr_accessor :failures

  def initialize
    self.failures = []
  end

  # "shovel method" takes result arg
  def << result
    # conditional for exception handling
    unless result.failure? then
      print "."
    else
      print "F"
      failures << result
    end
  end

  # a pretty summary for each test
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

# uncomment below to run

# class XTest < MicroTest
#   def add_2_and_2_equal_5_test
#     assert_equal(2+2, 5)
#   end
# end
#
# MicroTest.run_all_tests
