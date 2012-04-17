color = require 'cli-color'

{ extendedTypeOf } = require './util'

Theme =
  ' ': (s) -> s
  '+': color.green
  '-': color.red


subcolorize = (key, diff, output, color, indent) ->
  prefix    = if key then "#{key}: " else ''
  subindent = indent + '  '

  switch extendedTypeOf(diff)
    when 'object'
      if ('__old' of diff) and ('__new' of diff) and (Object.keys(diff).length is 2)
        subcolorize(key, diff.__old, output, '-', indent)
        subcolorize(key, diff.__new, output, '+', indent)
      else
        output color, "#{indent}#{prefix}{"
        for own subkey, subvalue of diff
          if m = subkey.match /^(.*)__removed$/
            subcolorize(m[1], subvalue, output, '-', subindent)
          else if m = subkey.match /^(.*)__added$/
            subcolorize(m[1], subvalue, output, '+', subindent)
          else
            subcolorize(subkey, subvalue, output, color, subindent)
        output color, "#{indent}}"

    when 'array'
      output color, "#{indent}#{prefix}["

      looksLikeDiff = yes
      for item in diff
        if (extendedTypeOf(item) isnt 'array') or (item.length != 2) or !(typeof(item[0]) is 'string') or item[0].length != 1 or !(item[0] in [' ', '-', '+', '~'])
          looksLikeDiff = no

      if looksLikeDiff
        for [op, subvalue] in diff
          if op is ' ' && !subvalue?
            subcolorize('', '...', output, ' ', subindent)
          else
            unless op in [' ', '~', '+', '-']
              throw new Error("Unexpected op '#{op}' in #{JSON.stringify(diff, null, 2)}")
            op = ' ' if op is '~'
            subcolorize('', subvalue, output, op, subindent)
      else
        for subvalue in diff
          subcolorize('', subvalue, output, color, subindent)

      output color, "#{indent}]"

    else
      output(color, indent + prefix + JSON.stringify(diff))


colorize = (diff, output) ->
  subcolorize('', diff, output, ' ', '')


colorizeToArray = (diff) ->
  output = []
  colorize(diff, (color, line) -> output.push "#{color}#{line}")
  return output


colorizeWithAnsiEscapes = (diff, options={}) ->
  output = []
  colorize diff, (color, line) ->
    if options.color
      output.push Theme[color]("#{color}#{line}") + "\n"
    else
      output.push "#{color}#{line}\n"
  return output.join('')


module.exports = { colorize, colorizeToArray, colorizeWithAnsiEscapes }
