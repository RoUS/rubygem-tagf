require('byebug')
require('yaml')

# advent.dat
# ----------
#
# Table 1: Long location descriptions.
# Table 2: Short location descriptions.
# Table 3: Map & movement data:
#   Column 1:  Current location
#   Column 2:  Target location (display Table1[Column 2] after move)
#   Column 3+: Keywords causing this motion
# Table 4: Vocabulary
#   Items 2-70 are motion keywords
#   Items 1001-1023 are items, scenery items, and adversaries
#
# Table 5: Static game states
#   Hundreds digit used to identify alternate states
# Table 6: Hints and events
#

puts('%YAML 1.1
---
')
tables			= []
data			= {}
ldata			= {}
#
# Read the entire file.
#
File.open('advent.dat-original', 'r') do |f|
  data			= f.readlines.map { |l| l.chomp.strip }
end

tnum			= 1
linenum			= 0
while (line = data.shift)
  linenum		+= 1
  unless (line.kind_of?(String))
    warn(format("Line %i is not a string\n", linenum))
  end
  if (line.split(%r!\s!).first.to_i == -1)
      tnum		+= 1
      next
  end
  if (tables[tnum].nil?)
    warn(format("Importing table %i\n", tnum))
    tables[tnum]	= []
  end
  #
  # Skip the header 'this is table N' line.
  #
  next if (line.to_i == tnum)
  line			= line.split(%r!\t!).map { |f| f.strip }.join("\t")
  tables[tnum]		<< line
end

#
# Tables all read into tables[1..7].  Time to make doughnuts out of
# 'em.  Variable 'data' has been exhausted and can be repurposed.
#

data			= {
  #
  # Location information, assembled from tables[1...3] (long
  # description, short description, and map/movement data).
  #
  # Format for a location element:
  #
  #	eid:		[String] Unique element identifier, like
  #			a slug.
  #	locnum:		[Integer] The location number from the ADVENT
  #			data file, which is used in table 3
  #			(map/movement).
  #	desc:		[String] Long description.
  #	brief:		[String] Short (one-line) description.  The
  #			EID will probably be determined by eyeballing
  #			this.
  #	cx:		[Hash] Definitions of how this location is
  #			connected to others.  For each element, the
  #			key is the 'other' location, and the value is
  #			an array of keyword numbers that will move the
  #			player from this location to the 'other' one.
  #
  locations:		{},
  #
  # Built from tables[4] (vocabulary).  The key for each element is
  # the keyword index, and the value is an array of the equivalent
  # strings (such as 'S' and 'SOUTH').
  #
  keywords:		{},
  #
  # 'Game states,' whatever that means, from Table 5.  Integer
  # key/index and a string value.
  #
  states:		{},
  #
  # 'Events' — notices and messages explicitly called out from the
  # source code.
  #
  events:		{},
}

#
# Process Table 1, the location long descriptions.
#
locnum			= -1
clocnum			= 0
tnum			= 1
dtable			= data[:locations]
while (line = tables[tnum].shift)
  (locnum,ldesc)	= line.split(%r!\t!)
  locnum		= locnum.to_i
  if (locnum != clocnum)
    if (dtable[locnum].nil?)
      dtable[locnum]	= {
        eid:		nil,
        locnum:		locnum,
        desc:		nil,
        brief:		nil,
        cx:		{},
      }
    end
    locdata		= dtable[locnum]
    clocnum		= locnum
  end
  if (ldesc.kind_of?(String))
    ldesc.strip!
    if (locdata[:desc])
      locdata[:desc]	<< "\n" << ldesc
    else
      locdata[:desc]	= ldesc
    end
  else
    warn(format("Location %i in table %i has bogus description",
                tnum, locnum))
  end
end

#
# On to Table 2, the location one-line descriptions.
#
locnum			= -1
clocnum			= 0
tnum			= 2
dtable			= data[:locations]
while (line = tables[tnum].shift)
  (locnum,ldesc)	= line.split(%r!\t!)
  locnum		= locnum.to_i
  if (locnum != clocnum)
    if (dtable[locnum].nil?)
      warn(format('Location %i is in table %i but not table 1',
                  locnum, tnum))
      dtable[locnum]	= {
        eid:		nil,
        locnum:		locnum,
        desc:		nil,
        brief:		nil,
        cx:		{},
      }
    end
    locdata		= dtable[locnum]
    clocnum		= locnum
  end
  if (ldesc.kind_of?(String))
    ldesc.strip!
    if (locdata[:brief])
      locdata[:brief]	<< "\n" << ldesc
    else
      locdata[:brief]	= ldesc
    end
  else
    warn(format("Location %i in table %i has bogus description",
                tnum, locnum))
  end
end

#
# Now do Table 3, the location connexion map.
#
locnum			= -1
clocnum			= 0
tnum			= 3
dtable			= data[:locations]
while (line = tables[tnum].shift)
  locs			= line.split(%r!\t!).map { |l| l.to_i }
  (locnum,target,how)	= locs
  if (locnum != clocnum)
    if (dtable[locnum].nil?)
      warn(format('Location %i is in table %i but not table 1 nor 2',
                  locnum, tnum))
      dtable[locnum]	= {
        eid:		nil,
        locnum:		locnum,
        desc:		nil,
        brief:		nil,
        cx:		{},
      }
    end
    locdata		= dtable[locnum]
    clocnum		= locnum
  end
  locdata[:cx][target]	||= []
  locdata[:cx][target]	|= [ *how ]
end

#
# Table 4: vocabulary (keywords).  Integer followed by a keyword
# assigned to it.  Multiple occurrences allowed for each integer key.
#
lwnum			= -1
ckwnum			= 0
tnum			= 4
dtable			= data[:keywords]
while (line = tables[tnum].shift)
  (kwnum,kword)		= line.split(%r!\t!)
  kwnum			= kwnum.to_i
  if (dtable[kwnum].nil?)
    dtable[kwnum]	= {
      keywords:		[ *kword ],
      flags:		[],
    }
  end
  kwdata		= dtable[kwnum]
  kwdata[:keywords]	|= [ *kword ]
  if (kwnum.between?(2, 70))
    kwdata[:flags]	|= [ :motion ]
  elsif (kwnum.between?(1001, 1023))
    kwdata[:flags]	|= [ :item ]
  end
end

#
# Table 5: Static game states (?).  Hundreds digit used to identify
# alternate states.
#
lwnum			= -1
ckwnum			= 0
tnum			= 5
dtable			= data[:states]
while (line = tables[tnum].shift)
  (sindex,svalue)	= line.split(%r!\t!)
  svalue.strip!
  sindex		= sindex.to_i
  altstate		= sindex / 100
  sbase			= sindex - (altstate * 100)
  if (dtable[sbase].nil?)
    dtable[sbase]	= {}
  end
  dtable[sbase][altstate] = svalue
end

#
# Table 6: Hints and events.  Format is essentially identical to Table
# 1, except that the indices are hardcoded into the source.
#
enum			= -1
cenum			= 0
tnum			= 6
dtable			= data[:events]
while (line = tables[tnum].shift)
  (enum,edesc)		= line.split(%r!\t!)
  enum			= enum.to_i
  if (enum != cenum)
    if (dtable[enum].nil?)
      dtable[enum]	= {
        eid:		nil,
        enum:		enum,
        text:		nil,
      }
    end
    edata		= dtable[enum]
    cenum		= enum
  end
  if (edesc.kind_of?(String))
    edesc.strip!
    if (edata[:text])
      edata[:text]	<< "\n" << edesc
    else
      edata[:text]	= edesc
    end
  else
    warn(format('Entry %i in table %i has non-string value',
                enum, tnum))
  end
end

puts(data.to_yaml)

puts('# Local Variables:
# mode: yaml
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
')

# Local Variables:
# mode: ruby
# indent-tabs-mode: nil
# eval: (if (intern-soft "fci-mode") (fci-mode 1))
# End:
