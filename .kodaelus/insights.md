2026-07-01 | assistant/commands | Command parse runs before FAQ in resolver; how-to prefixes must return null from tryParseAssistantCommand so goals.add_complete FAQ still wins.
2026-07-01 | test/screens/ai_chat_screen | Widget tests that confirm assistant goal create should use deadlineHours:0 in draft or bootstrap timezone — persistCreatePlan schedules notifications and needs timezone local.
