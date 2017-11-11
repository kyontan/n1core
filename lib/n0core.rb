# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/deep_dup'

class Object
  unless respond_to? :yield_self
    def yield_self(*args)
      yield(self, *args)
    end
  end
end

module N0core
  class BooleanClass
    def self.===(rhs)
      rhs == true || rhs == false
    end
  end

  class Spec
    attr_reader :version, :annotations, :spec

    def initialize(hash = nil)
      if self == Spec
        raise NotImplementedError, "You must implement #{self.class}##{__method__}"
      end

      if (h = hash.deep_dup.deep_symbolize_keys!)
        @version = h[:version]
        @annotations = h[:annotations] || []
        @spec = h[:spec]
      else
        @version = 0
        @annotations = []
      end
    end

    def to_hash
      {
        version: @version,
        annotations: @annotations,
        spec: @spec
      }.deep_stringify_keys
    end

    def to_yaml
      to_hash.to_yaml
    end
  end

  # client -> api
  class Spec0 < Spec
    attr_reader :templates

    def initialize(hash = nil)
      super

      if hash
        hash = hash.deep_dup.deep_symbolize_keys!
        @templates = hash[:templates] || {}
      end
    end

    def valid?
      invalid_reason = []
      invalid_reason << '`version` should be 0' if @version != 0
      invalid_reason << '`annotations` should be a Hash (Map)' unless @annotations.is_a? Hash
      invalid_reason << '`spec` should be a Hash (Map)' unless @spec.is_a? Hash
      invalid_reason << '`templates` should be a Hash (Map)' unless @templates.is_a? Hash

      # TODO: resources validation ...

      if invalid_reason.empty?
        true
      else
        [false, invalid_reason]
      end
    end

    def to_spec1
      spec = @spec.map do |name, object|
        expand_object(name, object)
      end

      Spec1.new(
        version: @version,
        annotations: @annotations,
        spec: spec
      )
    end

    def to_hash
      {
        version: @version,
        annotations: @annotations,
        templates: @templates,
        spec: @spec
      }.deep_stringify_keys
    end

    private

    # expand a object using template with args
    # TODO: needs to implement variable expansion
    #
    # @parameter object: { from_templates: [{ name: "something", args: { ... } }] }
    # @returns { type: "some_resource", ... }
    def expand_object(name, object)
      object.delete(:from_templates)&.inject({}) do |override_values, from_template|
        template_name = from_template[:name]
        args = from_template[:args] || {}

        template = @templates[template_name.to_sym].clone

        args_def = translate_args(template.delete(:args))

        check_args(args_def: args_def, args: args, template_name: name)

        args.each do |arg_name, arg_value|
          template = recursive_gsub(template, "__#{arg_name}__", arg_value.to_s)
        end

        override_values.deep_merge(template) # TODO: check conflicts and raise
      end.deep_merge(object)
    end

    def check_args(args_def:, args:, template_name:)
      check_insufficient_args(args_def, args, template_name)
      check_arg_types(args_def, args, template_name)
    end

    def check_insufficient_args(args_def, args, template_name)
      insufficient_fields = args_def.keys - args.keys
      return true if insufficient_fields.empty?

      raise "In template \"#{template_name}\", arguments are insufficient: #{sufficient_fields}"
    end

    def check_arg_types(args_def, args, template_name)
      type_errors = []
      args_def.each do |arg_name, arg_class|
        next if arg_class === args[arg_name]

        type_errors << "#{arg_name} (expected: #{arg_class}, actual: #{args[arg_name].class})"
      end

      return true if type_errors.empty?

      raise "In template \"#{template_name}\", arguments type missmatch: #{type_errors.join(', ')}"
    end

    # recursive gsub!
    # @parameter hash: { String : Object }
    # @note: pattern and replace are treated same as String#gsub(pattern, replace)
    def recursive_gsub(obj, pattern, replace)
      case obj
      when String then obj.gsub(pattern, replace)
      when Hash then obj.map { |k, v| [k, recursive_gsub(v, pattern, replace)] }.to_h
      when Array then obj.map { |x| recursive_gsub(x, pattern, replace) }
      else obj
      end
    end

    # { Symbol : String } -> { Symbol -> Class }
    # @parameter args: { ip_octet: "int" }
    # @returns { ip_octet: Integer }
    def translate_args(args)
      args
        .map { |name, typename| [name, typename_to_class(typename)] }
        .to_h
    end

    # String -> Class
    # @parameter typename: String
    # @return Class
    # @example: 'int' -> Integer
    def typename_to_class(typename)
      case typename.downcase
      when 'number', 'int', 'integer' then Integer
      when 'float', 'double' then Float
      when 'str', 'string', 'char' then String
      when 'bool' then BooleanClass
      when 'null', 'nil' then NilClass
      else raise "#{typename} can't convert to class"
      end
    end
  end

  # api -> scheduler
  class Spec1 < Spec
  end

  # scheduler -> agent, agent -> scheduler
  class Spec2 < Spec
  end

  class Object
    def initialize
      if self == Object
        raise NotImplementedError, "You must implement #{self.class}##{__method__}"
      end
    end
  end

  class Agent < Object
    def initialize
      if self == Object
        raise NotImplementedError, "You must implement #{self.class}##{__method__}"
      end
    end
  end

  class Agent::Compute < Agent
    class Kvm < Compute; end
  end

  class Agent::Porter < Agent
    class Flat < Porter; end
  end

  class Agent::Networker < Agent
    class Bgp < Networker; end
  end

  class Agent::Volumer < Agent
    class File < Volumer; end
  end

  class Resource < Object
    def initialize
      if self == Object
        raise NotImplementedError, "You must implement #{self.class}##{__method__}"
      end
    end

    def valid?
      raise NotImplementedError, "You must implement #{self.class}##{__method__}"
    end
  end

  # class Resource::Host < Resource; end
  class Resource::Network < Resource; end
  class Resource::Port < Resource; end
  class Resource::Vm; end
  class Resource::Volume < Resource; end
  class Resource::VolumeSnapshot < Resource; end

  class Resource::Network::Flat < Resource::Network; end
  class Resource::Network::Vlan < Resource::Network; end
  class Resource::Port::Vlan < Resource::Port; end
  class Resource::Vm::Kvm < Resource::Vm; end
  class Resource::Volume::File < Resource::Volume; end
  class Resource::Volume::Nfs < Resource::Volume; end
end
