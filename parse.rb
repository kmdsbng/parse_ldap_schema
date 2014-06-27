# -*- encoding: utf-8 -*-
require 'pp'

def main
  schema_files = detect_schema_files
  classes = load_and_parse_schema_files(schema_files)
  print_schema(classes)
end

def detect_schema_files
  Dir.glob('/etc/openldap/schema/*.schema')
  #['/etc/openldap/schema/cosine.schema']
end

def load_and_parse_schema_files(schema_files)
  schema_files.flat_map {|schema_file|
    parse_schema(File.read(schema_file), File.basename(schema_file))
  }
end

def parse_schema(schema_str, basename)
  schema_str.scan(/^(objectclass\s*(?<paren>\((?:\g<paren>|[^()])*\)))/im).map {|m|
    parse_object_class(m[0], basename)
  }
end

def parse_object_class(m, basename)
  names = []
  if m =~ /\bNAME\s*(?<quote>['"])(?<name>[^'"]*)\k<quote>/im
    names = [$2]
  elsif m =~ /\bNAME\s*\(([^)]*)\)/im
    names = $1.scan(/(?<quote>['"])(?<name>[^'"]*)\k<quote>/).map {|ary| ary[1]}
  end

  sups = []
  m.scan(/\bSUP\s+(\w+)\s+(\w+)/i).each {|sup|
    sups << sup
  }

  {:names => names, :sups => sups, :fname => basename}
end

def print_schema(classes)
  h = Hash.new {|h,k| h[k] = []}
  classes.each {|c|
    names = c[:names]
    sups = c[:sups].map {|ary| ary[0]}
    fname = c[:fname]
    sups.each {|sup|
      h[sup] += names.map {|name| [name, fname]}
      h[sup].uniq!
    }
  }
  pp traverse_class_tree(h, 'top')
end

def traverse_class_tree(h, parent)
  h[parent].inject({}) {|m,(child,fname)|
    m["#{child}(#{fname})"] = traverse_class_tree(h, child)
    m
  }
end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  # {spec of the implementation}
end

