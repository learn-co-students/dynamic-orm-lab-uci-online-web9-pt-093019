require_relative "../config/environment.rb"
require 'active_support/inflector'
class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end
  def self.column_names
    sql = "PRAGMA table_info(#{self.table_name})"
    array_of_hashes = DB[:conn].execute(sql)
    column_names = []
    array_of_hashes.each do |hash|
      column_names << hash["name"]
    end
    column_names
  end
  def initialize(attributes={})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end
  def table_name_for_insert
    self.class.table_name
  end
  def col_names_for_insert
    #binding.pry
    self.class.column_names.delete_if do |column_name|
      column_name == "id"
    end.join(", ")
  end
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{self.send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
  def save
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES(#{self.values_for_insert})
    SQL
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end
  def self.find_by(attribute)
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys[0].to_s} = ?"
    DB[:conn].execute(sql, attribute.values[0])
  end
end
