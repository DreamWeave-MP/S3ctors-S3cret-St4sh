---@meta
---@omw-context runtime

---Calendar configuration used by `openmw_aux.calendar`.
---@class openmw_aux.calendarconfig
---@field monthsDuration integer[] Number of days in each month.
---@field daysInWeek integer Number of days in a week.
---@field startingYear integer Starting year.
---@field startingYearDay integer Starting day of the starting year.
---@field startingWeekDay integer Starting weekday.

---@alias openmw_aux.calendarconfig.Config openmw_aux.calendarconfig

---@type openmw_aux.calendarconfig
local calendarconfig = {
  monthsDuration = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
  daysInWeek = 7,
  startingYear = 2008,
  startingYearDay = 151,
  startingWeekDay = 0,
}

return calendarconfig
