# frozen_string_literal: true

require_relative './test_helper'

class MediaTypesTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::MediaTypes::VERSION
  end

  def test_it_requires
    %i[
      Constructable
      Dsl
      Formatter
      Hash
      Object
      Scheme
      Validations
    ].each do |klazz|
      assert MediaTypes.const_defined?(klazz),
             format('Expected %<klazz>s to be required', klazz: klazz)
    end
  end

  # Test the default is a string
  class NoKeyTypeSpecified
    include MediaTypes::Dsl

    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      empty
    end
  end

  class StringKeyTypeSpecified
    include MediaTypes::Dsl
    expect_string_keys
    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      empty
    end
  end

  class SymbolKeyTypeSpecified
    include MediaTypes::Dsl
    expect_symbol_keys
    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      empty
    end
  end

  class KeyTypeSpecifiedAfterValidationBlock
    include MediaTypes::Dsl
    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      empty
    end

    expect_string_keys
  end
  # Supposed to FAIL!!!

  # refactor media types to match above
  def test_by_default_the_key_type_expected_is_a_symbol
    assert NoKeyTypeSpecified.symbol_keys?
    refute NoKeyTypeSpecified.string_keys?
  end

  def test_can_set_a_media_type_to_expect_string_keys_outside_any_module
    refute StringKeyTypeSpecified.symbol_keys?
    assert StringKeyTypeSpecified.string_keys?
  end

  def test_can_set_a_media_type_to_expect_symbol_keys_outside_any_module
    assert SymbolKeyTypeSpecified.symbol_keys?
    refute SymbolKeyTypeSpecified.string_keys?
  end

  def test_cannot_specify_key_type_after_validation_block
    assert_raises do
      KeyTypeSpecifiedAfterValidationBlock.class_eval do
        expect_string_keys
        # Class
        # Make it assert a specific error class
      end
    end

    assert_raises do
      KeyTypeSpecifiedAfterValidationBlock.class_eval do
        expect_symbol_keys
      end
    end
  end

  # Test that you can over-ride the default for a module
  module ModuleSpecifiesStringKeys
    MediaTypes.expect_string_keys

    class ShouldInheritKeyType
      include MediaTypes::Dsl

      def self.organisation
        'domain.test'
      end

      use_name 'test'

      validations do
        empty
      end
    end
  end

  def test_string_keys_can_be_set_for_a_module
    assert ModuleSpecifiesStringKeys::ShouldInheritKeyType.string_keys?
    refute ModuleSpecifiesStringKeys::ShouldInheritKeyType.symbol_keys?
  end

  module ParentMediaTypeModule
    MediaTypes.expect_string_keys
    module NestedModuleA
      MediaTypes.expect_symbol_keys
      class ShouldExpectSymbolKeys
        include MediaTypes::Dsl

        def self.organisation
          'domain.test'
        end

        use_name 'test'

        validations do
          empty
        end
      end

      module NestedModuleB
        MediaTypes.expect_string_keys
        class ShouldExpectStringKeys
          include MediaTypes::Dsl

          def self.organisation
            'domain.test'
          end

          use_name 'test'

          validations do
            empty
          end
        end
      end

      module NestedModuleC
        class ShouldExpectStringKeys
          include MediaTypes::Dsl

          def self.organisation
            'domain.test'
          end

          use_name 'test'

          validations do
            empty
          end
        end
      end
    end
  end
  def test_key_preferences_can_be_inherited_by_a_module
  end

  def test_that_key_settings_can_be_overridden_in_nested_modules
    # test_you_can_switch_back_to_symbol_keys_in_a_nested_module
    assert ParentMediaTypeModule::NestedModuleA::ShouldExpectSymbolKeys.symbol_keys?
    refute ParentMediaTypeModule::NestedModuleA::ShouldExpectSymbolKeys.string_keys?
    # test you can switch back to string keys in a nested module
    assert ParentMediaTypeModule::NestedModuleA::NestedModuleB::ShouldExpectStringKeys.string_keys?
    refute ParentMediaTypeModule::NestedModuleA::NestedModuleB::ShouldExpectStringKeys.symbol_keys?
  end

  # Check the media type over-rides the module
  module StringKeyModuleToBeOverRidden
    MediaTypes.expect_string_keys

    class OverridingMediaType
      include MediaTypes::Dsl
      expect_symbol_keys

      def self.organisation
        'domain.test'
      end

      use_name 'test'

      validations do
        empty
      end
    end
  end

  module SymbolKeyModuleToBeOverRidden
    class OverridingMediaType
      include MediaTypes::Dsl
      expect_symbol_keys

      def self.organisation
        'domain.test'
      end

      use_name 'test'

      validations do
        empty
      end
    end
  end

  # TODO: Should be in the previous(???)
  def test_symbol_keys_can_set_for_a_media_type
    assert StringKeyModuleToBeOverRidden::OverridingMediaType.symbol_keys?
    refute StringKeyModuleToBeOverRidden::OverridingMediaType.string_keys?

    refute SymbolKeyModuleToBeOverRidden::OverridingMediaType.symbol_keys?
    assert SymbolKeyModuleToBeOverRidden::OverridingMediaType.string_keys?
  end

  # Test Clashes
  module ModuleTriesToSetTwice
    MediaTypes.expect_string_keys
  end
  class MediaTypeTriesToSetKeyTypeTwice

    include MediaTypes::Dsl

    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      attribute :foo, Numeric
    end
  end

  def test_key_settings_cannot_be_altered_on_the_same_level_once_set
    assert_raises ModuleTriesToSetTwice.module_eval('MediaTypes.expect_symbol_keys')
    assert_raises do
      MediaTypeTriesToSetKeyTypeTwice.class_eval do
        expect_string_keys
        expect_symbol_keys
      end
    end
  end
  # Test too late
  class UnspecifiedKeysMediaType
    include MediaTypes::Dsl

    def self.organisation
      'domain.test'
    end

    use_name 'test'

    validations do
      empty
    end
  end

  def test_key_settings_for_a_media_type_have_to_precede_validations_being_called
    assert_raises do
      UnspecifiedKeysMediaType.class_eval do
        expect_string_keys
      end
    end
  end

  # Change to you cannot change for  a module once the default is used.
  module ModuleDefinesExpectationsAfterMediaTypes
    class ShouldExpectSymbols
      include MediaTypes::Dsl

      def self.organisation
        'domain.test'
      end

      use_name 'test'

      validations do
        empty
      end
    end

    MediaTypes.expect_string_keys
  end

  def test_cannot_change_module_expectations_after_default_used
    assert_raises do
      ModuleDefinesExpectationsAfterMediaTypes.module_eval('MediaTypes.expect_string_keys')
    end
  end

  module TreeTestRoot; end

  def test_module_tree_inheritance_structure_works_as_expected
    module_tree = build_module_tree(TreeTestRoot)
    failed = validate_inheritance_tree(module_tree)
    assert failed.empty?, failed.to_s + ' did not have the expected key types'
  end

  private

  def demodulize(mod)
    mod = mod.to_s
    if (i = mod.rindex('::'))
      mod[(i + 2)..-1]
    else
      mod
    end
  end

  def validate_inheritance_tree(module_tree)
    module_tree.each_with_object([]) do |target_module, failed|
      validate_module(failed, target_module)
    end
  end

  def validate_module(failed, target_module)
    case demodulize(target_module)
    when demodulize(NoKeyTypeSpecified)
      failed << target_module.name unless validate_module_inheritance(target_module)
    when demodulize(StringKeyTypeSpecified)
      failed << target_module.name unless Kernel.const_get(target_module.name + '::TestMediaType').string_keys?
    when demodulize(SymbolKeyTypeSpecified)
      failed << target_module.name unless Kernel.const_get(target_module.name + '::TestMediaType').symbol_keys?
    else
      failed
    end
  end

  def validate_module_inheritance(target_module)
    expected = (target_module.name.split('::') - [demodulize(NoKeyTypeSpecified)]).pop
    if expected == demodulize(StringKeyTypeSpecified)
      Kernel.const_get(target_module.name + '::TestMediaType').string_keys?
    else
      Kernel.const_get(target_module.name + '::TestMediaType').symbol_keys?
    end
  end

  def build_module_tree(target_module, depth = 1, module_tree = [])
    # This method creates a tree of nested modules, three levels deep,
    # with all combinations of key type inheritance covered.
    if depth >= 4
      return module_tree
    end

    # Creates three modules, with different key type specifications
    no_key_type_module = target_module.const_set('NoKeyTypeSpecified', Module.new)
    string_key_type_module = target_module.const_set('StringKeyTypeSpecified', Module.new { MediaTypes.expect_string_keys })
    symbol_key_type_module = target_module.const_set('SymbolKeyTypeSpecified', Module.new { MediaTypes.expect_symbol_keys })
    [no_key_type_module, string_key_type_module, symbol_key_type_module].each do |module_type|
      module_tree << module_type
      target_media_type = Class.new
      target_media_type.class_eval do
        include MediaTypes::Dsl

        def self.organisation
          'domain.test'
        end

        use_name 'test'

        validations do
          empty
        end
      end
      build_module_tree(module_type, depth + 1, module_tree)
      module_type.const_set('TestMediaType', target_media_type)
    end
    module_tree
  end
end
