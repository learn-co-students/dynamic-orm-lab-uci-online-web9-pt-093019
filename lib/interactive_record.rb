require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def initialize (attributes={})
    attributes.each {|key, value| self.send("#{key}=", value)}
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info(#{table_name})"

    table_info = DB[:conn].execute(sql)
    column_names = []

    table_info.each {|col| column_names << col["name"]}

    column_names.compact
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    key = attribute.keys.first
    value = "'#{attribute.values[0]}'"

    sql = "SELECT * FROM #{table_name} WHERE #{key} = #{value};"
    DB[:conn].execute(sql)
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if do |name|
      name == "id"
    end.join(", ")
  end

  def values_for_insert
    values = []

    self.class.column_names.each do |name|
      values << "'#{send(name)}'" unless send(name).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

end
