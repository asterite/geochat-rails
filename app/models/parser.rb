# coding: utf-8

require 'strscan'

class Parser < StringScanner
  def initialize(string, lookup = nil, options = {})
    super(string)
    @lookup = lookup
    @parse_signup_and_join = options[:parse_signup_and_join]
  end

  def self.parse(string, lookup = nil, options = {})
    self.new(string, lookup, options).parse
  end

  def parse
    # Skip first spaces
    scan /\s*/

    # Check blast
    options = {}
    options[:blast] = check_blast

    # Check if first token is a group
    if scan /^(@)?\s*(.+?)\s+(.+?)$/i
      group = self[2]
      if !group.command? && (self[1] && target = UnknownTarget.new(group)) || (@lookup && target = @lookup.get_target(group))
        options[:targets] = [target]

        rest = StringScanner.new self[3]

        # Check command for when a group is specified first
        unless target.is_a? UserTarget
          Node::CommandsWithoutGroup.each do |node_class|
            node = node_class.scan rest
            if node
              node.group = group
              node.after_scan_with_group
              return node
            end
          end
        end

        # Check more targets
        while rest.scan /^\s*(@)?\s*(.+?)\s+(.+?)$/i
          if rest[1]
            options[:targets] << UnknownTarget.new(rest[2])
            rest = StringScanner.new rest[3]
          elsif @lookup
            target = @lookup.get_target rest[2]
            if target
              options[:targets] << target
              rest = StringScanner.new rest[3]
            else
              rest.unscan
              break
            end
          else
            rest.unscan
            break
          end
        end

        # Just continue parsing the message with the given targets
        self.string = rest.string

        node = parse_message_with_location options
        return node if node

        return MessageNode.new options.merge(:body => string)
      end

      # No, it was not a target... go back
      unscan
    end

    # Check if it's a message with location
    node = parse_message_with_location options
    return node if node

    # Check signup and join in one command
    if scan /^(.+?)\s*>\s*(\S+)\s*$/i
      return SignupNode.new :display_name => self[1].strip, :group => self[2]
    end

    if @parse_signup_and_join && scan(/^\s*(.+?)\s*(?:join|\!)\s*(\S+)\s*$/i)
      return SignupNode.new :display_name => self[1].strip, :group => self[2]
    end

    # Check other commands
    Node::Commands.each do |node_class|
      node = node_class.scan self
      if node
        node.after_scan
        return node
      end
    end

    # It's just a message
    MessageNode.new options.merge(:body => string)
  end

  At = "(?:at|l:)?"
  NS = "(N|S)?"
  EW = "(E|W)?"
  Sign = "(?:\\+|\\-)?"
  FloatNumber = "(#{Sign}\\s*\\d+(?:\\.\\d+)?)"
  IntNumber = "(\\d+)?"
  TwoDotsNumber = "(#{Sign}\\s*\\d+\\.\\d+\\.\\d+)"
  TwoCommasNumber = "(#{Sign}\\s*\\d+\\,\\d+\\,\\d+)"
  ThreeDotsNumber = "(#{Sign}\\s*\\d+\\.\\d+\\.\\d+\\.\\d+)"
  ThreeCommasNumber = "(#{Sign}\\s*\\d+\\,\\d+\\,\\d+\\,\\d+)"
  Sep = "(?:\\s*\\*?\\s*|\\s+)"
  DegOrSpace = "(?:\\s*°\\s*|\\s+)"
  OptDeg = "\\s*°?\\s*"
  Minutes = "(?:\\s*'\\s*|\\s+)"
  OptMinutes = "\\s*'?\\s*"
  Seconds = "(?:\\s*''\\s*)?"
  StarComma = "(?:\\*|,)"
  SlashLocation = "\\/(.+?)\\/"
  OptSlashLocation = "\\/?(.+?)\\/?"
  NoSlash = "([^\\/]+)"
  Blast = "(!)?"

  LocatedMessageTwoDots = /^#{At}?\s*#{NS}\s*#{TwoDotsNumber}#{OptDeg}#{NS}#{Sep}#{EW}\s*#{TwoDotsNumber}#{OptDeg}#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageTwoCommas = /^#{At}?\s*#{NS}\s*#{TwoCommasNumber}#{OptDeg}#{NS}#{Sep}#{EW}\s*#{TwoCommasNumber}#{OptDeg}#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageThreeDots = /^#{At}?\s*#{NS}\s*#{ThreeDotsNumber}#{OptDeg}#{NS}#{Sep}#{EW}\s*#{ThreeDotsNumber}#{OptDeg}#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageThreeCommas = /^#{At}?\s*#{NS}\s*#{ThreeCommasNumber}#{OptDeg}#{NS}#{Sep}#{EW}\s*#{ThreeCommasNumber}#{OptDeg}#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageFloatDeg = /^#{At}?\s*#{NS}\s*#{FloatNumber}\s*°\s*#{NS}(?:\s*#{StarComma}?\s*|\s+)#{EW}\s*#{FloatNumber}\s*°\s*#{EW}\s*\*?\s*([^\s\d].+?)?$/i
  LocatedMessageFloatDegMinSec = /^#{At}?\s*#{NS}\s*#{FloatNumber}#{DegOrSpace}#{IntNumber}#{Minutes}#{IntNumber}#{Seconds}\s*#{NS}(?:\s*#{StarComma}?\s*|\s+)#{EW}\s*#{FloatNumber}#{OptDeg}#{IntNumber}#{OptMinutes}#{IntNumber}#{Seconds}\s*#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageFloat = /^#{At}?\s*#{NS}\s*#{FloatNumber}\s*#{NS}(?:\s*#{StarComma}\s*|\s+)#{EW}\s*#{FloatNumber}\s*#{EW}\s*\*?\s*(.+?)?$/i
  LocatedMessageAtOptSlash = /^#{At}?\s+#{OptSlashLocation}\s*\*\s*#{NoSlash}?$/i
  LocatedMessageAtSlash = /^#{At}?\s+#{SlashLocation}\s*#{Blast}\s*(.+?)?$/i
  LocatedMessageOptSlash = /^#{OptSlashLocation}\s*\*\s*#{NoSlash}?$/i
  LocatedMessageAtSlash2 = /^(?:#{At}\s+)?\s*\/#{NoSlash}$/i
  LocatedMessageAtOptSlash2 = /^#{At}\s+#{OptSlashLocation}$/i
  LocatedMessageSlash = /^#{SlashLocation}\s*#{Blast}\s*(.+?)?$/i

  def parse_message_with_location(options = {})
    if scan LocatedMessageTwoDots
      loc = location 1, 3, 4, 6, 2, 5, '.'
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageTwoCommas
      loc = location 1, 3, 4, 6, 2, 5, ','
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageThreeDots
      loc = location 1, 3, 4, 6, 2, 5, '.'
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageThreeCommas
      loc = location 1, 3, 4, 6, 2, 5, ','
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageFloatDeg
      loc = [self[2].without_spaces.to_f, self[5].without_spaces.to_f]
      apply_sign loc, 1, 3, 4, 6
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageFloatDegMinSec
      loc = [self[2].without_spaces, self[3], self[4], self[7].without_spaces, self[8], self[9]].to_location
      apply_sign loc, 1, 5, 6, 10
      MessageNode.new options.merge(:location => loc, :body => self[11].try(:strip))
    elsif scan LocatedMessageFloat
      loc = [self[2].without_spaces.to_f, self[5].without_spaces.to_f]
      apply_sign loc, 1, 3, 4, 6
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan LocatedMessageAtOptSlash
      MessageNode.new options.merge(:location => self[1], :body => self[2].try(:strip))
    elsif scan LocatedMessageAtSlash
      MessageNode.new options.merge(:location => self[1], :body => self[3].try(:strip), :blast => self[2] ? true : options[:blast])
    elsif scan LocatedMessageOptSlash
      if self[1] == 'help'
        unscan
        return
      end
      MessageNode.new options.merge(:location => self[1], :body => self[2].try(:strip))
    elsif scan LocatedMessageAtSlash2
      pieces = self[1].split ' ', 2
      if pieces[1] && pieces[1].start_with?('!')
        options[:blast] = true
        pieces[1] = pieces[1][1 .. -1].strip
      end
      MessageNode.new options.merge(:location => pieces[0], :body => pieces[1])
    elsif scan LocatedMessageAtOptSlash2
      MessageNode.new options.merge(:location => self[1])
    elsif scan LocatedMessageSlash
      MessageNode.new options.merge(:location => self[1], :body => self[3].try(:strip), :blast => self[2] ? true : options[:blast])
    else
      nil
    end
  end

  private

  def signs(*cardinals)
    [sign(cardinals[0], cardinals[1]), sign(cardinals[2], cardinals[3])]
  end

  def sign(*cardinals)
    cardinals.any?{|x| self[x] == 'S' || self[x] == 'W'} ? -1 : 1
  end

  def location(ns1, ns2, ew1, ew2, lat, lon, sep)
    loc = (self[lat].without_spaces.split(sep) + self[lon].without_spaces.split(sep)).to_location
    apply_sign loc, ns1, ns2, ew1, ew2
    loc
  end

  def apply_sign(loc, ns1, ns2, ew1, ew2)
    s = signs ns1, ns2, ew1, ew2
    loc[0] = loc[0] * s[0]
    loc[1] = loc[1] * s[1]
  end

  def check_blast
    if scan /^!\s*(.+?)$/i
      self.string = self[1]
      true
    else
      nil
    end
  end
end

class Target
  attr_accessor :name
  attr_accessor :payload
  def initialize(name, payload = nil)
    @name = name
    @payload = payload
  end

  def ==(other)
    self.class == other.class && self.name == other.name
  end
end

class GroupTarget < Target; end
class UserTarget < Target; end
class UnknownTarget < Target; end
