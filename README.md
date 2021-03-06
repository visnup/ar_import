ArImport
========

Utilizes MySQL's INSERT INTO table VALUES (), (), () syntax to do quicker
bulk importing of data.


Example
=======

Old Way: (which generates one SQL statement per person.)

    lots_of_people = File.open 'people.yml' { |f| YAML.load f }

    lots_of_people.each do |attributes|
      Person.create attributes
    end

New Way: (generates one SQL statement per 200 people.)

    Person.import do |p|
      lots_of_people.each do |attributes|
        p.create attributes
      end
    end

You can also give import an existing array to insert:

    Person.import lots_of_people


Copyright (c) 2009 Visnu Pitiyanuvath, released under the MIT license
