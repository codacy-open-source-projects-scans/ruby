# frozen_string_literal: false
require 'test/unit'

class TestCase < Test::Unit::TestCase
  def test_case
    case 5
    when 1, 2, 3, 4, 6, 7, 8
      assert(false)
    when 5
      assert(true)
    end

    case 5
    when 5
      assert(true)
    when 1..10
      assert(false)
    end

    case 5
    when 1..10
      assert(true)
    else
      assert(false)
    end

    case 5
    when 5
      assert(true)
    else
      assert(false)
    end

    case "foobar"
    when /^f.*r$/
      assert(true)
    else
      assert(false)
    end

    case
    when true
      assert(true)
    when false, nil
      assert(false)
    else
      assert(false)
    end

    case "+"
    when *%w/. +/
      assert(true)
    else
      assert(false)
    end

    case
    when *[], false
      assert(false)
    else
      assert(true)
    end

    case
    when *false, []
      assert(true)
    else
      assert(false)
    end

    begin
      verbose_bak, $VERBOSE = $VERBOSE, nil
      assert_raise(NameError) do
        eval("case; when false, *x, false; end")
      end
    ensure
      $VERBOSE = verbose_bak
    end
  end

  def test_deoptimization
    assert_in_out_err(['-e', <<-EOS], '', %w[42], [])
      class Symbol; undef ===; def ===(o); p 42; true; end; end; case :foo; when :foo; end
    EOS

    assert_in_out_err(['-e', <<-EOS], '', %w[42], [])
      class Integer; undef ===; def ===(o); p 42; true; end; end; case 1; when 1; end
    EOS
  end

  def test_optimization
    case 1
    when 0.9, 1.1
      assert(false)
    when 1.0
      assert(true)
    else
      assert(false)
    end
    case 536870912
    when 536870911.9, 536870912.1
      assert(false)
    when 536870912.0
      assert(true)
    else
      assert(false)
    end
    case 0
    when 0r
      assert(true)
    else
      assert(false)
    end
    case 0
    when 0i
      assert(true)
    else
      assert(false)
    end
  end

  def test_method_missing
    flag = false

    case 1
    when Class.new(BasicObject) { def method_missing(*) true end }.new
      flag = true
    end

    assert(flag)
  end

  def test_nomethoderror
    assert_raise(NoMethodError) {
      case 1
      when Class.new(BasicObject) { }.new
      end
    }
  end

  module NilEqq
    refine NilClass do
      def === other
        false
      end
    end
  end

  class NilEqqClass
    using NilEqq

    def eqq(a)
      case a; when nil then nil; else :not_nil; end
    end
  end


  def test_deoptimize_nil
    assert_equal :not_nil, NilEqqClass.new.eqq(nil)
  end
end
