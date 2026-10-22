-- Author-written microfiction for the Story X library, not copies of licensed children's books.
-- Book IDs are stable keys for one-time rewards and future multilingual expansion.
local catalog={
    {
        id="bubble_voyage",language="ru",age="7+",genre="Приключение и наблюдательность",
        title="Путешествие на мыльном пузыре",author="Оригинальный текст библиотеки YUGATNEO",
        paragraphs={
            "В небольшом городе Лина придумала путешествие на мыльном пузыре. Она не знала, выдержит ли пузырь вес человека, поэтому сделала игрушечную корзинку для бумажного путешественника. Так опыт стал безопасным и всё равно увлекательным.",
            "Ветер перенёс корзинку над парком. С высоты Лине показалось, будто дорожки образуют огромную спираль. Но она поняла, что узор сверху и узор на земле могут выглядеть по-разному.",
            "Когда пузырь опустился рядом с прудом, бумажный путешественник оказался целым. Лина записала время, направление ветра и место приземления, чтобы сравнить результаты следующего опыта.",
            "Дома Лина нарисовала карту, а рядом оставила пустое поле для новых наблюдений. Она решила: догадка полезна, но догадку нельзя путать с тем, что удалось проверить."
        },
        locate="В каком абзаце Лина записала время, ветер и место приземления?",locateAnswer=3,
        understand="Почему Лина оставила пустое поле на карте?",
        answers={"Чтобы скрыть дорогу", "Чтобы оставить место неизвестному и новым наблюдениям",
            "Потому что закончились карандаши", "Чтобы нарисовать чужой дом"}, understandAnswer=2,
    },
    {
        id="mirrors",language="ru",age="9+",genre="Логика и взаимопонимание",
        title="Мира и три зеркала",author="Оригинальный текст библиотеки YUGATNEO",
        paragraphs={
            "Мира вошла в зал, где стояли три зеркала. Одно показывало предметы точно, второе увеличивало их, а третье меняло местами правую и левую стороны. На дверях была надпись: «Не спеши с выводом».",
            "На столе лежал красный куб. В первом зеркале он казался маленьким, во втором — огромным, а в третьем был обращён другой гранью. Сам куб оставался прежним.",
            "Мира попросила друга проверить её догадку. Они измерили куб линейкой и сравнили свои записи. Каждый заметил деталь, которую другой сначала пропустил.",
            "Покидая зал, друзья оставили для следующего посетителя заметку: «Картина помогает исследовать мир, но не заменяет сам предмет и восприятие другого человека»."
        },
        locate="В каком абзаце друзья используют линейку?",locateAnswer=3,
        understand="Какой вывод помогает сделать опыт с зеркалами?",
        answers={"Размер куба всегда меняется", "Одному наблюдателю всегда виднее",
            "Разные изображения не обязательно означают разный предмет", "Любое зеркало бесполезно"}, understandAnswer=3,
    },
    {
        id="clockwork_garden",language="en",age="8+",genre="Problem solving",
        title="The Clockwork Garden",author="Original YUGATNEO Library story",
        paragraphs={
            "Every morning, Ari visited a garden with mechanical flowers. Each flower opened only when sunlight touched a small silver dial. A cloudy day gave Ari a new question to investigate.",
            "Ari tried placing a mirror beside the first flower. The reflected beam reached the dial and the petals opened. Then Ari moved the mirror one step; a second flower opened instead.",
            "The gardener offered Ari a prize for opening all four flowers. Rather than guessing, Ari drew a diagram of the paths that light could take and tested one path at a time.",
            "At sunset Ari understood that an incorrect attempt was useful when it revealed something new. Ari saved the diagram so that the next visitor could test a different route."
        },
        locate="Which paragraph describes a diagram of possible light paths?",locateAnswer=3,
        understand="What made Ari's final attempts more systematic?",
        answers={"A lucky guess", "Making a map and testing one route at a time",
            "Closing the flowers", "Ignoring the mirror"}, understandAnswer=2,
    },
    {
        id="kite_and_stars",language="en",age="10+",genre="Memory and discovery",
        title="The Astronomer's Kite",author="Original YUGATNEO Library story",
        paragraphs={
            "Noor built a kite with four colored ribbons. Red marked north, blue marked south, green marked east and gold marked west. The ribbons helped Noor remember the directions.",
            "One evening the kite fell beside an observatory. A telescope stood near the window, but its lens was covered with dust. Noor asked permission before cleaning it.",
            "Through the clean telescope, Noor could see a bright planet and several stars. A friend pointed out that stars seem to move across the sky while the ground feels still.",
            "Noor wrote two columns in a notebook: what the telescope showed and what might explain it. The second column contained several possibilities instead of a single quick answer."
        },
        locate="Which paragraph mentions two columns in a notebook?",locateAnswer=4,
        understand="What was the purpose of the two notebook columns?",
        answers={"To separate observation from possible explanations", "To track race cars",
            "To record only one belief", "To draw the ribbons"}, understandAnswer=1,
    },
}
local Library={}
function Library.list()
    local out={}
    for _,book in ipairs(catalog) do
        table.insert(out,{id=book.id,title=book.title,author=book.author,age=book.age,
            language=book.language,genre=book.genre})
    end
    return out
end
function Library.get(id)
    if type(id)~="string" then return nil end
    for _,book in ipairs(catalog) do if book.id==id then return book end end
end
return Library
