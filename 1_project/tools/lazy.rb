#!/usr/bin/python

###############################################################################################
# The script takes a mapper and a reducer and tries to vary its parameters.
#
# Parameters need to be marked as such using specially formatted comments.
# A parameter can also have constraints and general constraints can be formulated.
#
# Parameters are introduced with a following comment.
#     PARAM = VALUE # |P a..b|
#
# Constraints are introduced with a separate conmment.
#     # |C A*B < 100|
#
# The allowed operations are:
#   *, +, -, /, %
#
# The allowed comparisons are:
#   <, <=, =, >=, >
#
# Additionally, braces can be used to group operations.
###############################################################################################

class Unary
   attr_reader :value

   def eval
      @value
   end
end

class Constant < Unary
   attr_reader :content

   # Initializes a new variable.
   #
   # === Params:
   # +content+:: The content of the variable.
   def initialize(content)
      @content = content 
      @value   = content.to_i if not content.include? '.'
      @value   = content.to_f if not content.include? '.'
   end
end

class Variable < Unary
   attr_reader :name

   # Initializes a new variable.
   #
   # === Params:
   # +name+:: The name of the variable.
   def initialize(name, symt)
      @name = name
      @symt = symt
   end

   def value
      @name
   end

   def eval
      @symt.fetch value, nil
   end
end

class Negate
   # Initializes a new negation.
   #
   # === Params:
   # +value+:: The value to negate.
   def initialize(value)
      @value = value
   end

   def eval
      v = @value.eval
      -v
   end
end

class Binary
   attr_reader :left
   attr_reader :right
end


class Multiplication < Binary
   # Initializes a new multiplication.
   #
   # === Params:
   # +left+::  The left hand side of the multiplication.
   # +right+:: The right hand side of the multiplication.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l * r
   end
end

class Division < Binary
   # Initializes a new division.
   #
   # === Params:
   # +left+::  The numerator of the division.
   # +right+:: The denominator of the division.
   def initialize(left, right)
      @left  = left
      @right = right 
   end

   def eval
      l = @left.eval
      r = @right.eval
      l / r
   end
end

class Addition < Binary
   # Initializes a new addition.
   #
   # === Params:
   # +left+::  The left summand of the addition.
   # +right+:: The right summand of the addition.
   def initialize(left, right)
      @left  = left
      @right = right 
   end

   def eval
      l = @left.eval
      r = @right.eval
      l + r
   end
end

class Subtraction < Binary
   # Initializes a new subtraction.
   #
   # === Params:
   # +left+::  The left pariticpant of the subtraction.
   # +right+:: The value to be subtracted.
   def initialize(left, right)
      @left  = left
      @right = right 
   end

   def eval
      l = @left.eval
      r = @right.eval
      l - r
   end
end

class Modulo < Binary
   # Initializes a new value modulation.
   #
   # === Params:
   # +left+::  The left participant of the modulation.
   # +right+:: The right participant of the modulation.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l % r
   end
end

class LT < Binary
   # Initializes a new comparison.
   #
   # === Params:
   # +left+::  The left participant of the comparison.
   # +right+:: The right participant of the comparison.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l < r
   end
end

class LET < Binary
   # Initializes a new comparison.
   #
   # === Params:
   # +left+::  The left participant of the comparison.
   # +right+:: The right participant of the comparison.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l <= r
   end
end

class EQ < Binary
   # Initializes a new comparison.
   #
   # === Params:
   # +left+::  The left participant of the comparison.
   # +right+:: The right participant of the comparison.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l == r
   end
end

class GET < Binary
   # Initializes a new comparison.
   #
   # === Params:
   # +left+::  The left participant of the comparison.
   # +right+:: The right participant of the comparison.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l >= r
   end
end

class GT < Binary
   # Initializes a new comparison.
   #
   # === Params:
   # +left+::  The left participant of the comparison.
   # +right+:: The right participant of the comparison.
   def initialize(left, right)
      @left  = left
      @right = right
   end

   def eval
      l = @left.eval
      r = @right.eval
      l > r
   end
end

#----------------------------------------------------------------------------------------
# PARSER

class Token
   ADD = 0
   SUB = 1
   MUL = 2
   DIV = 3
   MOD = 4

   LPAR = 5
   RPAR = 6

   LT  = 7
   LET = 8
   GT  = 9
   GET = 10
   EQ  = 11

   NUM = 12
   VAR = 13

   E = 14

   attr_reader :kind
   attr_reader :content

   # Initializes a new token with the specified kind.
   #
   # === Params:
   # +kind+::     The kind of the token.
   # +content+::  The content of the token.
   def initialize(kind, content)
      @kind    = kind
      @content = content 
   end
end

class Scanner
   # Initializes a new scanner for the specified formula.
   #
   # === Params:
   # +formula+:: A string containing the formula to parse.
   def initialize(formula)
      @formula  = formula
      @buffer   = formula
      @previous = nil
   end

   # Gets the next token in the formula.
   def next_token
      token = 
         case @buffer
         when /\A\+/ then
            Token.new Token::ADD, $&
         when /\A-/  then
            Token.new Token::SUB, $&
         when /\A\// then
            Token.new Token::DIV, $&
         when /\A\*/ then
            Token.new Token::MUL, $&
         when /\A\d+(\.\d+)?/ then
            Token.new Token::NUM, $&
         when /\A\(/ then
            Token.new Token::LPAR, $&
         when /\A\)/ then
            Token.new Token::RPAR, $&
         when /\A\W+/ then
            Token.new Token::VAR, $&
         else 
            Token.new Token::E, ''
         end

      @buffer   = $'
      @previous = token

      token
   end

   # Gets the last created token.
   def current_token
      @previous
   end
end

