require "resource_allow_header/version"

require 'active_support/concern'
require 'active_support/core_ext/module/attribute_accessors'

module ResourceAllowHeader
  class Error < StandardError; end

  extend ActiveSupport::Concern
  protected

  HEADER_ALLOW = 'Allow'

  mattr_accessor :implicit_resource_proc, :can_proc

  def self.configure(&block)
    block_given? ? instance_exec(self, &block) : self
  end

  included do
    attr_accessor :current_action_lazy_allows
    after_action :set_allow_header

    def set_allow_header
      response.header[HEADER_ALLOW] = compute_allow_header.join(', ')
    end

    def compute_allow_header(resource: implicit_resource)
      Hash(current_action_lazy_allows).each_with_object([]) do |(method, allow), result|
        allowable_resource = allow[:resource]&.call || resource
        next unless allow?(allow[:action], allowable_resource)
        result << method
      end
    end
  end

  class_methods do
    # noinspection RubyStringKeysInHashInspection
    HTTP_ABILITY_METHOD_MAP = {
      'HEAD' => :show,
      'GET' => :show,
      'POST' => :create,
      'PUT' => :update,
      'PATCH' => :update,
      'DELETE' => :destroy
    }.freeze

    def allow(http_method, ability_action = map_http_method_to_ability_action(http_method), **options, &block)
      before_action(**options) do
        allow_resource = block_given? && proc { instance_exec(&block) } || nil

        self.current_action_lazy_allows = Hash(current_action_lazy_allows).merge(
          http_method => { resource: allow_resource, action: ability_action }
        )
      end
    end

    def map_http_method_to_ability_action(http_method)
      HTTP_ABILITY_METHOD_MAP[http_method]
    end
  end

  protected

  def allow?(action, resource)
    if can_proc.respond_to?(:call)
      return instance_exec(action, resource, self, &can_proc)
    end

    can?(action, resource)
  end

  private

  def implicit_resource
    if implicit_resource_proc.respond_to?(:call)
      return instance_exec(self, &implicit_resource_proc)
    end

    @allow_resource || @resource
  end
end
