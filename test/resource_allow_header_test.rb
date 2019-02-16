require "test_helper"

class ResourceAllowHeaderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ResourceAllowHeader::VERSION
  end

  class MyResource
    def initialize(data)
      @data = data
    end

    def to_s
      'MyResource (data: %s)' % data
    end

    attr_reader :data

    private

    attr_writer :data
  end

  class Action
    def initialize(method  = nil, only: [], except: [], &block)
      self.action_method = method
      self.only = Array(only)
      self.except = Array(except)
      self.block = block
    end

    def call(action, instance)
      return if !only.empty? && !only.include?(action)
      return if except.include?(action)

      action_method ? instance.send(action_method) : instance.instance_exec(&block)
    end

    private

    attr_accessor :only, :except, :block, :action_method
  end

  class BaseController
    class << self
      attr_reader :before_actions, :after_actions
    end

    def initialize
      @response = OpenStruct.new(header: {})
    end

    attr_reader :response

    def self.before_action(method = nil, **options, &block)
      @before_actions = Array(@before_actions).concat([Action.new(method, **options, &block)])
    end

    def self.after_action(method = nil, **options, &block)
      @after_actions = Array(@after_actions).concat([Action.new(method, **options, &block)])
    end

    def do_action(action)
      Array(self.class.before_actions).each do |before_action|
        before_action.call(action, self)
      end

      send(action)

      Array(self.class.after_actions).each do |after_action|
        after_action.call(action, self)
      end
    end

    def can?(action, resource)
      if resource.data.is_a?(Numeric)
        return resource.data < 4 if action == :show
        return resource.data < 2 if action == :create
      end
      resource.data == action || (resource.data.respond_to?(:include?) && resource.data.include?(action))
    end
  end

  class FakeController < BaseController
    include ResourceAllowHeader

    # You can GET only the show and index paths
    allow('GET', only: %i[show index]) { @instance }

    # You can DELETE only the resource at the show path
    allow('DELETE', only: :show)

    # You can post only on the "index path"
    allow('POST', only: :index) { MyResource.new(0) }

    def show
      @instance = MyResource.new(1)

      # Or use the implicit one
      @allow_resource = MyResource.new(:destroy)
    end

    def index
      # Expect to be able to see (SHOW) this "index" resource
      @resource = MyResource.new(3)
      @a_different_resource = MyResource.new(:nope)
    end
  end

  def setup
    @controller = FakeController.new
  end

  def teardown
    ResourceAllowHeader.configure do
      self.implicit_resource_proc = nil
      self.can_proc = nil
    end
  end

  def test_it_allows_a_method_if_it_authorizes
    @controller.do_action(:show)
    assert_includes @controller.response.header['Allow'], 'GET'
  end

  def test_it_allows_implicit_resources_via_allow_resource
    @controller.do_action(:show)
    assert_includes @controller.response.header['Allow'], 'DELETE'
  end

  def test_it_honours_callback_options
    @controller.do_action(:index)
    assert_includes @controller.response.header['Allow'], 'GET'
    assert_includes @controller.response.header['Allow'], 'POST'
  end

  def test_it_can_use_a_custom_can_proc
    ResourceAllowHeader.configure do
      self.can_proc = proc { |action| action != :show }
    end

    @controller.do_action(:show)
    refute_includes @controller.response.header['Allow'], 'GET'
    assert_includes @controller.response.header['Allow'], 'DELETE'
  end

  def test_it_can_use_a_custom_implicit_resource_proc
    ResourceAllowHeader.configure do
      self.implicit_resource_proc = proc { @a_different_resource || MyResource.new(:nothing) }
    end

    @controller.do_action(:index)
    refute_includes @controller.response.header['Allow'], 'GET'
    assert_includes @controller.response.header['Allow'], 'POST'
  end

end
