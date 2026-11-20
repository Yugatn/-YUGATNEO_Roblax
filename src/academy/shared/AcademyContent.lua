--!strict
-- Shared, age-appropriate scenario content. Author's "social organism" is a metaphor.
-- This content is deliberately nonpartisan. The adult health course is not imported here.
local AcademyContent = {}

AcademyContent.order = {"water", "bridge", "council"}

AcademyContent.levels = {
    water = {
        title = "Вода для каждого",
        shortTitle = "Городская вода",
        ageHint = "6+",
        description = "Исследуй городскую сеть: школа, дома и клиника зависят друг от друга.",
        reflection = "Что произойдет с соседями, если оставить один район без воды?",
        center = Vector3.new(-125, 0, 0),
        color = Color3.fromRGB(36, 156, 206),
        winAction = "activate",
        order = {"inspect", "prepare", "clinic", "school", "homes", "activate"},
        actions = {
            inspect = {
                label = "Осмотреть насос",
                hint = "Сначала разберись, почему пропала вода.",
                feedback = "Вы выяснили, что общая подача нарушена. Начните с фильтра.",
                requires = {},
            },
            prepare = {
                label = "Очистить фильтр",
                hint = "После осмотра подготовь систему к ремонту.",
                feedback = "Фильтр очищен. Теперь можно распределить работу по районам.",
                requires = {"inspect"},
            },
            clinic = {
                label = "Клиника: трубы",
                hint = "Для больницы нужна бесперебойная вода.",
                feedback = "В клинике снова работает водоснабжение.",
                requires = {"prepare"},
            },
            school = {
                label = "Школа: трубы",
                hint = "Школе нужны чистая вода и санитария.",
                feedback = "Школа подключена к общей сети.",
                requires = {"prepare"},
            },
            homes = {
                label = "Дома: трубы",
                hint = "Проверь, чтобы ни один жилой квартал не остался без воды.",
                feedback = "Дома подключены к воде: осталось открыть главный клапан.",
                requires = {"prepare"},
            },
            activate = {
                label = "Открыть клапан",
                hint = "Убедись, что школа, клиника и дома подключены.",
                feedback = "Весь город обеспечен водой! Успех зависит от всех частей системы.",
                requires = {"clinic", "school", "homes"},
            },
        },
    },

    bridge = {
        title = "Мост сотрудничества",
        shortTitle = "Мост",
        ageHint = "6+",
        description = "Построй безопасный мост между соседями. В одиночку — последовательно, в группе — вместе.",
        reflection = "Какая проверка защитила тех, кто будет пользоваться мостом?",
        center = Vector3.new(0, 0, 0),
        color = Color3.fromRGB(94, 180, 117),
        winAction = "open",
        order = {"survey", "plan", "beamLeft", "beamRight", "test", "open"},
        actions = {
            survey = {
                label = "Осмотреть берег",
                hint = "Изучи местность и потребности жителей.",
                feedback = "Вы нашли удобное место для будущего моста.",
                requires = {},
            },
            plan = {
                label = "Согласовать план",
                hint = "Продумай конструкцию до начала строительства.",
                feedback = "План согласован: можно разделить работу.",
                requires = {"survey"},
            },
            beamLeft = {
                label = "Левая опора",
                hint = "Установи первую конструкцию.",
                feedback = "Левая опора готова.",
                requires = {"plan"},
            },
            beamRight = {
                label = "Правая опора",
                hint = "Поставь вторую конструкцию.",
                feedback = "Правая опора готова.",
                requires = {"plan"},
            },
            test = {
                label = "Проверить прочность",
                hint = "Без проверки опасно открывать путь.",
                feedback = "Мост выдержал проверку безопасности.",
                requires = {"beamLeft", "beamRight"},
            },
            open = {
                label = "Открыть мост",
                hint = "Сначала пройди испытание.",
                feedback = "Мост открыт! Сотрудничество соединяет два района.",
                requires = {"test"},
            },
        },
    },

    council = {
        title = "Совет города",
        shortTitle = "Совет города",
        ageHint = "10+",
        description = "Школу не отремонтировали в срок. Проверь сведения и выбери мирный путь решения.",
        reflection = "Каких сведений пока не хватает? Какие доводы могут быть у несогласных?",
        center = Vector3.new(125, 0, 0),
        color = Color3.fromRGB(184, 131, 213),
        winGroup = "resolution",
        order = {"budget", "residents", "engineers", "meeting", "petition", "audit"},
        actions = {
            budget = {
                label = "Изучить бюджет",
                hint = "Проверь документы, прежде чем делать выводы.",
                feedback = "По плану на ремонт выделены средства, но причины задержки не указаны.",
                requires = {},
            },
            residents = {
                label = "Выслушать жителей",
                hint = "Узнай, что видят и чего опасаются люди.",
                feedback = "Жители сообщают о закрытой библиотеке и неудобствах для детей.",
                requires = {},
            },
            engineers = {
                label = "Спросить инженеров",
                hint = "Сравни свидетельства с техническим заключением.",
                feedback = "Инженеры нашли дополнительные повреждения. Требуется уточнить сроки и расходы.",
                requires = {},
            },
            meeting = {
                label = "Открытая встреча",
                hint = "Обсуди ситуацию с жителями, специалистами и администрацией.",
                feedback = "Встреча позволяет услышать стороны, но требует времени и фасилитации.",
                requires = {"budget", "residents", "engineers"},
                group = "resolution",
            },
            petition = {
                label = "Обращение с фактами",
                hint = "Составь точный запрос о сроках и безопасности.",
                feedback = "Обращение фиксирует вопросы, но ответ нужно проверить по результатам.",
                requires = {"budget", "residents", "engineers"},
                group = "resolution",
            },
            audit = {
                label = "Независимая проверка",
                hint = "Попроси проверку расходов и инженерных оценок.",
                feedback = "Проверка повышает прозрачность, но также требует ресурсов.",
                requires = {"budget", "residents", "engineers"},
                group = "resolution",
            },
        },
    },
}

return AcademyContent
