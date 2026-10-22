-- Original short reading passages for the Story X educational library.
-- Copyrighted works and unverified translations are not bundled.
local Catalog = {}
Catalog.books = {
 {id="island",title="Остров трёх вопросов",author="YUGATNEO original",age="8+",paragraphs={
 "На берегу острова стояли три маяка. Каждый светился по-своему, но лишь один показывал путь к библиотеке.",
 "Мира предложила не спорить о красоте огней. Она записала время вспышек и сравнила результаты.",
 "Когда облака рассеялись, друзья заметили четвёртый огонёк: это была лодка, которую сначала приняли за маяк.",
 "Прежде чем выбирать объяснение, полезно проверить, что именно было увидено."
 },questions={
 {q="Кто записал время вспышек?",options={"Мира","Смотритель","Капитан"},answer=1,paragraph=2},
 {q="Что сперва приняли за маяк?",options={"Лодку","Звезду","Башню"},answer=1,paragraph=3}
 }},
 {id="forest",title="Сад памяти",author="YUGATNEO original",age="7+",paragraphs={
 "В саду было семь тропинок, но на карте нарисовали только шесть.",
 "Лея объединила ориентиры в группы: мост, фонтан и высокое дерево.",
 "Вернувшись через час, она заметила, что фонтан больше не работал, а остальные ориентиры были на своих местах.",
 "Друзья поняли, что память надёжнее, если проверять её, а не полагаться только на первое впечатление."
 },questions={
 {q="Сколько тропинок было в саду?",options={"Шесть","Семь","Восемь"},answer=2,paragraph=1},
 {q="Что перестало работать?",options={"Мост","Фонтан","Часы"},answer=2,paragraph=3}
 }},
 {id="spiral",title="Дорога по спирали",author="YUGATNEO original",age="9+",paragraphs={
 "Спиральная дорога вела на вершину. За каждым поворотом открывалась новая задача.",
 "Юный исследователь увидел того, кому было трудно подняться. Он остановился, чтобы помочь.",
 "На следующем витке они нашли тихую комнату для отдыха и свободного возвращения.",
 "На вершине путники построили указатель, чтобы следующему путешественнику было легче."
 },questions={
 {q="Для чего была тихая комната?",options={"Для отдыха","Для наказания","Для торговли"},answer=1,paragraph=3},
 {q="Что построили на вершине?",options={"Указатель","Башню","Статуэтку"},answer=1,paragraph=4}
 }},
 {id="lights",title="Письма светлячков",author="YUGATNEO original",age="6+",paragraphs={
 "Два светлячка посылали сигналы через пруд: один мигал быстро, другой медленно.",
 "Они приняли разный ритм за ссору, но потом спросили друг друга о причинах.",
 "Они придумали общий знак: три короткие вспышки означали «я слышу тебя».",
 "Друзья научились не приписывать другому мысли, о которых он сам не рассказывал."
 },questions={
 {q="Что означали три короткие вспышки?",options={"Я слышу тебя","Уходи","Я не знаю"},answer=1,paragraph=3},
 {q="Как друзья разрешили недоразумение?",options={"Спросили друг друга","Разошлись","Перестали светить"},answer=1,paragraph=2}
 }}
}
function Catalog.get(id)
 if type(id)~="string" then return nil end
 for _, book in ipairs(Catalog.books) do if book.id==id then return book end end
end
function Catalog.list()
 local result={}
 for _,book in ipairs(Catalog.books) do
  table.insert(result,{id=book.id,title=book.title,author=book.author,age=book.age,paragraphs=book.paragraphs})
 end
 return result
end
function Catalog.challenge(rng)
 local book=Catalog.books[rng:NextInteger(1,#Catalog.books)]
 local q=book.questions[rng:NextInteger(1,#book.questions)]
 return {bookId=book.id,bookTitle=book.title,prompt=q.q,options=q.options,paragraph=q.paragraph,answer=q.answer}
end
function Catalog.check(challenge,bookId,paragraph,answer)
 return challenge~=nil and bookId==challenge.bookId and paragraph==challenge.paragraph and answer==challenge.answer
end
return Catalog
