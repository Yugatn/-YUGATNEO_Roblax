-- STORY X / YUGATNEO: curated, original gallery captions for an in-world
-- interactive exhibition. Summaries are adaptations, not chapter quotations.
-- imageAsset is intentionally 0 until the author uploads licensed artwork.
local Catalog = {}
Catalog.exhibits = {
    {
        id="observer",title="Наблюдатель",chapter="Пролог / Предел восприятия",
        theme="subject",pattern=1,accent="cyan",imageAsset=0,
        caption="В начале пути не найден готовый ответ. Есть тот, кто наблюдает, и мир, который отвечает не на все вопросы.",
        story="Открывающая инсталляция задаёт вопрос: кто смотрит на мир, если сам наблюдатель — часть происходящего? Эта сцена предлагает различать событие, впечатление и вывод.",
        question="Что в этом зале следует отличать от интерпретации?",options={"Наблюдаемое событие","Цвет предметов","Звуковую дорожку"},answer=1,
        route="Matrix"
    },
    {
        id="mira",title="Мира — другой субъект",chapter="Мира / Взаимное наблюдение",
        theme="dual",pattern=2,accent="violet",imageAsset=0,
        caption="Мира существует не как декорация чужого рассказа. Её перспектива не обязана совпадать с моделью, построенной наблюдателем.",
        story="Югатн стремится понять Миру. Но Мира наблюдает его в ответ: исследователь тоже оказывается частью исследования. В изображении важны два независимых источника света.",
        question="Что меняется, когда Мира сама начинает наблюдать?",options={"Она перестаёт существовать","Наблюдатель становится наблюдаемым","Любые вопросы исчезают"},answer=2,
        route="Library"
    },
    {
        id="trace",title="След",chapter="След / Повторяющиеся структуры",
        theme="spiral",pattern=3,accent="green",imageAsset=0,
        caption="Повторяющийся знак может быть уликой, совпадением или ошибкой интерпретации. Необходимо научиться проверять след.",
        story="Спираль связывает прошлые и будущие витки истории. В ней можно двигаться, возвращаться, пересматривать прежние выводы и замечать новые связи.",
        question="Что полезнее сделать при обнаружении повторяющегося узора?",options={"Сразу объявить его доказательством","Игнорировать всё","Сравнить наблюдения и проверить гипотезу"},answer=3,
        route="Chess"
    },
    {
        id="symbiont",title="Симбионт",chapter="Беседы Югатна с искусственным интеллектом",
        theme="network",pattern=4,accent="cyan",imageAsset=0,
        caption="Человек и искусственный интеллект обсуждают границы знания. Любой алгоритм может помочь искать смысл, но не обязан знать всё.",
        story="Диалог становится частью повествования. Симбионт строит модели и задаёт вопросы, а Югатн проверяет их пределы и собственные предположения.",
        question="Почему вывод Симбионта следует проверять?",options={"Модель может ошибаться","Потому что она всегда права","Проверки запрещены"},answer=1,
        route="Arcade"
    },
    {
        id="tv",title="Телеэкран после перемен",chapter="Революция / СМИ и общество",
        theme="broadcast",pattern=5,accent="amber",imageAsset=0,
        caption="На экране появляются новости, общественные предложения и обсуждения ответственности. Зритель больше не только пассивный наблюдатель.",
        story="В этом игровом эпизоде люди рассматривают социальные реформы и их возможные последствия. Важно отличать обещания, эксперимент и проверенный результат.",
        question="Какая позиция помогает оценивать предложения?",options={"Слепое согласие","Проверка последствий и разных точек зрения","Запрет любых вопросов"},answer=2,
        route="Library"
    },
    {
        id="catharsis",title="Cinema Catharsis",chapter="Изображение и переживание",
        theme="film",pattern=6,accent="violet",imageAsset=0,
        caption="Экран влияет на воображение, но изображение чужого опыта никогда не заменяет сам опыт другого.",
        story="Зал предлагает посетителю рассмотреть монтаж, контекст и рамку кадра. Что показано? Что скрыто? Что мы достраиваем сами?",
        question="Что не следует путать при просмотре истории?",options={"Кадр и целую реальность","Размер экрана и яркость","Название и номер зала"},answer=1,
        route="Arcade"
    },
    {
        id="future",title="Дневник 2300 года",chapter="ИИ из будущего / Историческая петля",
        theme="clock",pattern=7,accent="green",imageAsset=0,
        caption="ИИ будущего изучает двадцать первый век. Чем дальше во времени архив, тем важнее различать запись и реконструкцию.",
        story="Художественный архив пытается понять события прошлого, сопоставляя свидетельства. Реконструкция может быть убедительной, но не обязана совпадать с действительным событием.",
        question="Что должен помнить исследователь архивов?",options={"Каждый документ полон","Модель прошлого отличается от самого прошлого","Прошлое можно проверить без источников"},answer=2,
        route="Library"
    },
    {
        id="matrix",title="Пробуждение",chapter="Матрица / Переход через уровни",
        theme="code",pattern=8,accent="cyan",imageAsset=0,
        caption="Привычный мир становится кодом. Переход в новое измерение ставит вопрос: что остаётся неизменным для субъекта?",
        story="Путешествие через слои виртуальной реальности соединяется с игровой спиралью. Порталы нужны не только для смены пейзажа, но и для пересмотра собственной картины мира.",
        question="Что символизирует переход между измерениями?",options={"Только смену цвета","Проверку пределов привычной модели","Обязательную победу над людьми"},answer=2,
        route="Matrix"
    },
    {
        id="other",title="Другой",chapter="Амбивалентный солипсизм",
        theme="dual",pattern=9,accent="amber",imageAsset=0,
        caption="«Я есть. Ты есть. Я не отрицаю Тебя и твоего существования».",
        story="Экспозиция предлагает не сводить собеседника к образу в собственном восприятии. Это философская позиция персонажей, а не эмпирически доказанный игровой факт.",
        question="Какая идея выражена в центральной фразе?",options={"Отрицание Другого","Признание существования Другого","Запрет общения"},answer=2,
        route="Chess"
    },
    {
        id="unknown",title="Икс — неизвестное",chapter="Финальная открытая экспозиция",
        theme="void",pattern=10,accent="violet",imageAsset=0,
        caption="Даже большая система знаний может оставлять неизвестный остаток. Путешествие не обязано завершаться окончательным объяснением.",
        story="Последняя сцена оставляет место свободному поиску: вернуться к книгам, сыграть в шахматы, исследовать ещё одно измерение или остановиться.",
        question="Зачем оставлять неизвестное открытым?",options={"Чтобы не задавать вопросов","Чтобы сохранять возможность нового исследования","Чтобы никогда не учиться"},answer=2,
        route="Matrix"
    },
}
Catalog.routes={
 Matrix={title="В центральный мир",position=Vector3.new(0,6,13)},
 Chess={title="В шахматный зал",position=Vector3.new(500,6,48)},
 Library={title="В библиотеку X",position=Vector3.new(-139,6,64)},
 Arcade={title="В интеллектуальную аркаду",position=Vector3.new(104,6,30)},
}
local index={}
for _,exhibit in ipairs(Catalog.exhibits) do
    assert(not index[exhibit.id],"Duplicate gallery exhibit "..exhibit.id)
    assert(#exhibit.options==3 and exhibit.options[exhibit.answer]~=nil,"Bad gallery quiz")
    index[exhibit.id]=exhibit
end
function Catalog.find(id)
    if type(id)~="string" then return nil end
    return index[id]
end
function Catalog.public(exhibit)
    return {id=exhibit.id,title=exhibit.title,chapter=exhibit.chapter,caption=exhibit.caption,
        story=exhibit.story,question=exhibit.question,options=exhibit.options,
        imageAsset=exhibit.imageAsset,route=exhibit.route}
end
function Catalog.check(id,answer)
    local exhibit=Catalog.find(id)
    return exhibit and type(answer)=="number" and answer%1==0 and answer==exhibit.answer or false
end
return Catalog
