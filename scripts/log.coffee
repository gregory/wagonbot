# Description:
#   Create a log of events/reminders for later
# Commands:
#   hubot log - Returns the current log.
#   hubot log <my log entry> - Adds a new log entry
#   hubot log <id> - Disaply details about specific log entry
#   hubot log flush - clear the log
#   hubot log delete <num> - delete a single log entry
#   hubot log moreinfo <num> - get more lengthy information to a log entry
#   hubot log moreinfo <num> <lots of information> - set moreinfo for entry
#   !(logthis|handover|log) anywhere in a message to log it

# Moment is a class for formatting date/time
moment = require('moment')

addLogEntry = (robot, msg, index) ->
  logs = robot.brain.get('handover_log') or {}
  log = logs[msg.message.room] ||= []
  new_log = msg.match[index]

  userId = msg.message.user.name.toLowerCase()
  dateString = new Date()

  logentry = { Date: dateString, User: userId, Subject: new_log }
  log.push logentry
  robot.brain.set 'handover_log', logs

  msg.reply "Thanks #{userId}, Created entry num #{log.length}"

module.exports = (robot) ->

  robot.hear /^\!(logthis|handover|log)\s+(.*)/i, (msg) ->
    addLogEntry(robot, msg, 2)
    return 0

  robot.hear /(.*)\s+\!(logthis|handover|log)$/i, (msg) ->
    addLogEntry(robot, msg, 1)
    return 0

  robot.hear /(.*\s+\!(logthis|handover|log)\s+.*)/i, (msg) ->
    addLogEntry(robot, msg, 1)
    return 0

  robot.respond /log\s+(.*)/mi, (msg) ->
    logs = robot.brain.get('handover_log') or {}
    log = logs[msg.message.room] ||= []
    new_log = msg.match[1]

    if new_log.match(/^(flush|clear)$/)
      logs[msg.message.room] = []
      robot.brain.set 'handover_log', logs
      msg.reply "Log flushed"
      return 0

    if match = new_log.match(/^moreinfo\s*([0-9]+)?\s*(.*)?/)
      entry = match[1]
      moreinfo = match[2]

      if entry == undefined
        msg.reply "Which log entry do you want more info for?"
        return 0

      if moreinfo
        if log[entry - 1] == undefined
          msg.reply "Error: Log entry #{entry} does not exist"
          return 0

        entry_details = log[entry - 1]
        entry_details['moreinfo'] = moreinfo
        log[entry - 1] = entry_details
        robot.brain.set 'handover_log', logs
        msg.reply "Set moreinfo for #{entry} to #{moreinfo}"
        return 0

      if log[entry - 1]['moreinfo']
        msg.reply log[entry - 1]['moreinfo']
      else
        msg.reply "No extra info for entry #{entry}"

      return 0

    if match = new_log.match(/^delete\s*([0-9]+)?/)
      del = match[1]

      if del == undefined
        msg.reply "Which entry should I delete ?"
        return 0

      log.splice(del - 1, 1)
      robot.brain.set 'handover_log', logs
      msg.reply "Deleted log entry #{del}"
      return 0

    if match = new_log.match(/^([0-9])\s*$/)
      num = match[1]

      entry = log[num - 1]
      if entry == undefined
        msg.reply "There is no log entry for #{num}"
        return 0

      date = moment(entry['Date']).format('DD-MMM-YYYY @ HH:mm:ss')
      user = entry['User']
      subject = entry['Subject']
      moreinfo = ''
      if entry['moreinfo']
        moreinfo = "\n\n#{entry['moreinfo']}"

      msg.reply "```Entry: #{num}\nDate: #{date}\nLogged By: #{user}\n" +
                "Entry: #{subject}#{moreinfo}```"
      return 0

    if new_log
      addLogEntry(robot, msg, 1)

    logs = robot.brain.get('handover_log') or {}
    log = logs[msg.message.room] or null
    if log == null or log[1] == null
      msg.reply "There are no log entries yet"
      return 0

  robot.respond /log(\s+)?$/i, (msg) ->
    logs = robot.brain.get('handover_log') or {}
    log = logs[msg.message.room] or []

    unless log[0]
      msg.reply "There is no log yet... why not add an entry?"
      return 0

    count = 1
    output_log = ''
    for entry in log
      date = moment(entry['Date']).format('DD-MMM@HH:mm')
      user = "#{entry['User']}        ".substr(0,8)
      subject = entry['Subject']

      moreinfo_flag = ' '
      if entry['moreinfo']
        msg.reply "More info for #{count}"
        moreinfo_flag = '*'

      output_log = "#{output_log}#{count}: #{date} #{user} #{moreinfo_flag} " +
                   "| #{subject}\n"
      count = count + 1

    output_log = output_log.replace /\n$/g, ''
    msg.reply "Heres the handover log: \n```#{output_log}```"
