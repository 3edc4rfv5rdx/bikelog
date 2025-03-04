create table if not exists help (
    num INTEGER PRIMARY KEY,
    en text,
    ru text,
    ua text
);

INSERT OR REPLACE INTO help (num, en, ru, ua) values (1,
'This program is a digital diary for tracking the maintenance and repair
of your bicycles. It is suitable for:
1) Owners of one or more bicycles.
2) Families where each member has their own bicycle.
3) Entrepreneurs or enthusiasts who assist with repairs.
The program allows you to record all actions for each bicycle and owner. Data can be
exported to CSV for analysis in spreadsheet editors.
Getting started:
1) Add or select an owner.
2) Add a bicycle and enter its details.
Important:
1) The program is not a financial tool. Prices are for reference only.
2) It works without an internet connection. All data is stored locally
and is not shared with third parties',
'Эта программа — цифровой дневник для отслеживания обслуживания и ремонта
ваших велосипедов. Она подходит для:
1) Владельцев одного или нескольких велосипедов.
2) Семей, где каждый член имеет свой велосипед.
3)Предпринимателей или энтузиастов, помогающих в ремонте.
 Программа позволяет фиксировать все действия по каждому велосипеду и владельцу.
 Данные можно экспортировать в CSV для анализа в табличных редакторах.
 Как начать:
 1) Добавьте или выберите владельца.
 2) Добавьте велосипед и введите данные о нём.
 Важно:
 1) Программа не является финансовым инструментом. Цены носят справочный характер.
 2) Работает без интернета. Все данные хранятся локально и не передаются третьим лицам',
'Ця програма — це цифровий щоденник для відстеження обслуговування та ремонту вашого велосипеда.
Вона підходить для:
1) Власників одного або кількох велосипедів.
2) Сімей, де кожен член має свій велосипед.
3) Підприємців або ентузіастів, які допомагають у ремонті.
Програма дозволяє фіксувати всі дії для кожного велосипеда та власника. Дані можна
експортувати у формат CSV для аналізу в табличних редакторах.
Як почати:
1) Додайте або оберіть власника.
2) Додайте велосипед та введіть його дані.
Важливо:
1) Програма не є фінансовим інструментом. Ціни мають довідковий характер.
2) Працює без інтернету. Усі дані зберігаються локально та не передаються третім особам');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (2,
'Input actions. On this screen, you can enter actions and parameters that you want to save in the database',
'Ввод действий. На этом экране вы можете внести действия и параметры, которые хотите сохранить в базе данных',
'Введення дій. На цьому екрані ви можете внести дії та параметри, які хочете зберегти в базі даних');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (3,
'Filter settings screen. On this screen, you can select parameters to filter actions. You can choose one parameter or several, or all at once. When you have entered the data for filtering, click the "Apply" button. After that, the filtered data will be displayed on the main screen. You can also return to the filter screen and click the "Clear" button to return all filter fields to their original state',
'Экран установки фильтров. На этом экране вы можете выбрать параметры для фильтрации действий. Вы можете выбрать один параметр или несколько, или все сразу. Когда вы ввели данные для фильтрации, нажмите кнопку "Применить". После этого на главном экране будут отображены отфильтрованные данные. Также вы можете вернуться на экран фильтров и нажать кнопку "Очистить", чтобы вернуть все поля фильтров в исходное состояние',
'Екран налаштування фільтрів. На цьому екрані ви можете вибрати параметри для фільтрації дій. Ви можете вибрати один параметр або кілька, або всі відразу. Коли ви ввели дані для фільтрації, натисніть кнопку "Застосувати". Після цього на головному екрані будуть відображені відфільтровані дані. Також ви можете повернутися на екран фільтрів і натиснути кнопку "Очистити", щоб повернути всі поля фільтрів у початковий стан');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (4,
'Main settings. Customize program behavior and appearance. 1. Language selection. 2. Visible actions count (0 shows all). 3. Currency rate (price will be converted to national currency). 4. Multiple actions input (enable to input several actions without returning to the main screen). 5. Return after clear (enable to return to the main screen after clearing filters). 6. Round to integer (final action amount will be rounded to whole numbers)',
'Основные настройки. Настройте поведение и внешний вид программы. 1. Выбор языка. 2. Количество видимых действий (0 показывает все). 3. Курс валюты (цена будет пересчитана в национальную валюту). 4. Ввод нескольких действий (включите для ввода нескольких действий без возврата на главный экран). 5. Возврат после очистки (включите для возврата на главный экран после очистки фильтров). 6. Округление до целого (итоговая сумма действия будет округлена до целых чисел)',
'Основні налаштування. Налаштуйте поведінку та зовнішній вигляд програми. 1. Вибір мови. 2. Кількість видимих дій (0 показує всі). 3. Курс валюти (ціна буде перерахована в національну валюту). 4. Введення кількох дій (включіть для введення кількох дій без повернення на головний екран). 5. Повернення після очищення (включіть для повернення на головний екран після очищення фільтрів). 6. Округлення до цілого (підсумкова сума дії буде округлена до цілих чисел)');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (5,
'Reference management: Add - press (+), enter name, Save. Edit - long press on record = EDIT, edit name, Save. Delete - long press on record = DELETE, Save. Cancel = Back button',
'Справочники: Добавление - кнопка (+), ввод имени, Сохранить. Изменение - длинное нажатие на записи = EDIT, изменить имя, Сохранить. Удаление - длинное нажатие на записи = DELETE, Сохранить. Отмена = кнопка Назад',
'Довідники: Додавання - кнопка (+), введення імені, Зберегти. Зміна - довге натискання на запису = EDIT, змінити ім''я, Зберегти. Видалення - довге натискання на запису = DELETE, Зберегти. Відміна = кнопка Назад');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (6,
'Store your bikes data here with their owners, models and details',
'Соберите здесь данные о велосипедах, их владельцах и характеристиках',
'Зберіть тут дані про велосипеди, їх власників та характеристики');


INSERT OR REPLACE INTO help (num, en, ru, ua) values (7,
'From the settings screen, you can access application settings, directories of owners, types of bicycles, events, and a list of bicycles, as well as functions for saving (including CSV) and restoring data',
'С экрана настроек можно перейти к настройкам приложения, справочникам владельцев, типов велосипедов, событий и списку велосипедов, а также к функциям сохранения (включая CSV) и восстановления данных',
'З екрану налаштувань можна перейти до налаштувань програми, довідників власників, типів велосипедів, подій та списку велосипедів, а також до функцій збереження (включаючи CSV) та відновлення даних');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (8,
'Creates a new action',
'Создает новое действие',
'Створює нову дію');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (9,
'The ''Back'' button returns you to the previous screen. If you are editing information and have not saved the changes, they will be lost. Pressing this button on the main screen will close the program',
'Кнопка ''Назад'' возвращает вас на предыдущий экран. Если вы редактируете информацию и не сохранили изменения, они будут потеряны. Нажатие этой кнопки на главном экране закроет программу',
'Кнопка ''Назад'' повертає вас на попередній екран. Якщо ви редагуєте інформацію та не зберегли зміни, вони будуть втрачені. Натискання цієї кнопки на головному екрані закриє програму');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (10,
'Main menu',
'Основное меню программы',
'Основне меню програми');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (11,
'Filter actions by owner, bike, price range, date range, and comments',
'Фильтруйте действия по владельцу, велосипеду, диапазону цен, диапазону дат и комментариям',
'Фільтруйте дії за власником, велосипедом, діапазоном цін, діапазоном дат та коментарями');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (12,
'Here you can configure program parameters, edit reference books and perform database backup or restore operations',
'Здесь вы сможете настроить параметры программы, отредактировать справочники и выполнить операции сохранения или восстановления базы данных',
'Тут ви зможете налаштувати параметри програми, редагувати довідники та виконати операції збереження або відновлення бази даних');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (13,
'Here you can calculate the total expenses for all records or for filtered data only',
'Здесь вы сможете подсчитать общую сумму затрат по всем записям или только по отфильтрованным данным',
'Тут ви зможете підрахувати загальну суму витрат по всіх записах або тільки по відфільтрованих даних');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (14,
'Manual refresh of the screen content',
'Ручное обновление содержимого экрана',
'Ручне оновлення вмісту екрану');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (15,
'Information about the program, version and developer',
'Информация о программе, версии и разработчике',
'Інформація про програму, версію та розробника');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (16,
'Modify selected record',
'Изменить выбранную запись',
'Змінити вибраний запис');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (17,
'Delete selected record',
'Удалить выбранную запись',
'Видалити вибраний запис');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (18,
'Allows you to export the data currently visible in the list to a CSV file, taking into account any active filters',
'Позволяет выдать в файл формата CSV данные, которые сейчас видны в списке с учетом фильтра',
'Дозволяє видати у файл формату CSV дані, які зараз видно у списку з урахуванням фільтра');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (20,
'Language selection. Choose the language that suits your preferences',
'Выбор языка программы. Выберите язык, который соответствует вашим предпочтениям',
'Вибір мови програми. Виберіть мову, яка відповідає вашим вподобанням');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (21,
'Color theme lets you customize the appearance of the program. To change the theme, select the most comfortable option from the list, click Save and restart the program.',
'Цветовая тема позволяет настроить внешний вид программы. Для смены темы выберите наиболее комфортный для себя вариант из списка, нажмите кнопку "Сохранить" и перезапустите программу.',
'Кольорова тема дозволяє налаштувати зовнішній вигляд програми. Для зміни теми оберіть найбільш комфортний для себе варіант зі списку, натисніть кнопку "Зберегти" та перезапустіть програму.');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (22,
'Setting the number of visible actions. Since there can be a lot of actions, there is no need to show them all. You can choose the number of last actions that will be displayed on the screen. If the value 0 is selected, all actions will be displayed',
'Настройка числа видимых действий. Поскольку действий может быть очень много, нет необходимости показывать все. Вы можете выбрать количество последних действий, которые будут отображаться на экране. Если выбрано значение 0, будут показаны все действия',
'Налаштування кількості видимих дій. Оскільки дій може бути дуже багато, немає необхідності показувати їх усі. Ви можете вибрати кількість останніх дій, які будуть відображатися на екрані. Якщо вибрано значення 0, будуть показані всі дії');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (23,
'Currency rate setting. When entering a price, you can specify a dollar sign and
enter the price in dollars or another foreign currency. When saving data,
the price will be recalculated into the national currency according to the
course and saved in the national currency. In the comment, a mark with the amounts
will be indicated',
'Настройка курса валюты. При вводе цены, вы можете указать значок доллара и внести
цену в долларах или другой иностранной валюте. При сохранении данных цена будет
пересчитана в национальную валюту согласно курсу и сохранена в национальной валюте.
В комментарии будет указана отметка с суммами',
'Налаштування курсу валюти. При введенні ціни ви можете вказати знак долара та внести ціну
в доларах або іншій іноземній валюті. При збереженні даних ціна будет перерахована в
національну валюту згідно з курсом та збережена в національній валюті. У коментарі буде
вказано позначення з сумами');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (24,
'Checkbox "Entering multiple actions at once". If this checkbox is set, you can enter
multiple actions in a row without returning to the main screen. If the checkbox
is not set, the program will return to the main screen after each action is entered',
'Флажок "Ввод нескольких действий сразу". Если этот флажок установлен, вы можете вводить
несколько действий подряд без возврата на главный экран. Если флажок снят, после каждого
ввода действия программа будет возвращаться на главный экран',
'Флажок "Введення декількох дій відразу". Якщо цей флажок встановлено, ви можете вводити
декілька дій поспіль без повернення на головний екран. Якщо флажок знято, після кожного
введення дії програма буде повертатися на головний екран');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (25,
'Checkbox "Return after clearing". It sets the behavior of the filter screen when the
"Clear" button is pressed. If the checkbox is set, after clearing you will be returned
to the main screen, if not - you will stay on the filter screen',
'Флажок "Возврат после очистки". Он устанавливает поведение экрана фильтров при
нажатии кнопки "Очистить". Если флажок установлен, после очистки вы будете возвращены
на главный экран, если нет - останетесь на экране фильтров',
'Флажок "Повернення після очищення". Він встановлює поведінку екрану фільтрів при
натисканні кнопки "Очистити". Якщо флажок встановлено, після очищення ви будете
повернені на головний екран, якщо ні - залишитеся на екрані фільтрів');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (26,
'The "Round to integer" option displays monetary amounts without cents. When enabled, all amounts will be rounded to whole numbers.',
'Опция "Округление до целого" позволяет отображать денежные суммы без копеек. Если опция включена, все суммы будут округляться до целых значений.',
'Опція "Округлення до цілого" дозволяє відображати грошові суми без копійок. Якщо опція увімкнена, всі суми будуть округлятися до цілих значень.');


INSERT OR REPLACE INTO help (num, en, ru, ua) values (40,
'Choose owner or bike from the proposed lists',
'Выберите хозяина или велосипед из предложенных списков',
'Виберіть власника або велосипед із запропонованих списків');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (41,
'Enter the event date',
'Укажите дату события',
'Вкажіть дату події');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (42,
'Select event type from the list',
'Выберите тип события из списка',
'Виберіть тип події зі списку');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (43,
'Cost of work-parts-services in national or other currency. When $ is selected, the amount is automatically converted to national currency at the exchange rate from settings. Currency amount information will be added to the comment',
'Стоимость работы-услуги-запчастей в национальной или другой валюте. При выборе $ сумма автоматически конвертируется в национальную валюту по курсу из настроек. Информация о сумме в валюте добавится к комментарию',
'Вартість роботи-послуги-запчастин у національній або іншій валюті. При виборі $ сума автоматично конвертується в національну валюту за курсом з налаштувань. Інформація про суму у валюті додасться до коментаря');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (44,
'Any text comment to help recall event-operation details',
'Текстовый комментарий для деталей события-операции',
'Текстовий коментар для деталей події-операції');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (45,
'When the dollar checkbox is checked, the entered amount is automatically converted to the national currency, and information about the original amount is added to the comment',
'При отмеченном флажке доллара, введенная сумма автоматически переводится в национальную валюту, а информация об исходной сумме добавляется в комментарий',
'Якщо позначено прапорець долара, введена сума автоматично переводиться в національну валюту, а інформація про початкову суму додається до коментаря');


INSERT OR REPLACE INTO help (num, en, ru, ua) values (48,
'Enter or edit the bike owner name, type or event',
'Введите или отредактируйте название события, типа или имя владельца велосипеда',
'Введіть або відредагуйте назву події, типу або ім''я власника велосипеда');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (49,
'Press (+) to add new event name, type or bike owner name',
'Нажмите (+) для добавления нового названия события, типа или имени владельца велосипеда',
'Натисніть (+) для додавання нової назви події, типу або імені власника велосипеда');


INSERT OR REPLACE INTO help (num, en, ru, ua) values (50,
'Select a bicycle owner from the provided reference list',
'Выберите владельца велосипеда из предложенного списка',
'Виберіть власника велосипеда із запропонованого списку');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (51,
'Enter the name of the bicycle manufacturer',
'Введите название фирмы-производителя велосипеда',
'Введіть назву фірми-виробника велосипеда');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (52,
'Enter the model of the bicycle',
'Введите модель велосипеда',
'Введіть модель велосипеда');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (53,
'Select the type of bicycle from the list',
'Выберите тип велосипеда из списка',
'Виберіть тип велосипеда зі списку');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (54,
'Enter bike serial number - helps to identify your bike if stolen',
'Введите серийный номер велосипеда - поможет опознать велосипед при краже',
'Введіть серійний номер велосипеда - допоможе впізнати велосипед при крадіжці');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (55,
'Enter the date of purchase of the bicycle',
'Введите дату покупки велосипеда',
'Введіть дату купівлі велосипеда');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (57,
'Select photo path from storage, better move photos to /Download/BikeLogBackup first',
'Выбор пути к фото в памяти, лучше переместить фото в /Download/BikeLogBackup',
'Вибір шляху до фото у пам''яті, краще перемістити фото до /Download/BikeLogBackup');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (58,
'Click to save changes in database',
'Нажмите для сохранения изменений в базе',
'Натисніть для збереження змін у базі');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (59,
'Click to add a new bike to the database and don''t forget to save',
'Нажмите для добавления нового велосипеда в базу и не забудьте сохранить',
'Натисніть для додавання нового велосипеда до бази та не забудьте зберегти');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (60,
'Button to enter the main settings window',
'Кнопка входа в окно главных настроек',
'Кнопка входу в вікно головних налаштувань');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (61,
'Button to enter the directory of bicycle owners',
'Кнопка входа в справочник хозяев велосипедов',
'Кнопка входу в довідник власників велосипедів');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (62,
'Button to enter the directory of bicycle types',
'Кнопка входа в справочник типов велосипедов',
'Кнопка входу в довідник типів велосипедів');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (63,
'Button to enter the directory of events related to bicycles',
'Кнопка входа в справочник событий, связанных с велосипедами',
'Кнопка входу в довідник подій, пов’язаних з велосипедами');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (64,
'Button to enter the directory of bicycles',
'Кнопка входа в справочник велосипедов',
'Кнопка входу в довідник велосипедів');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (65,
'Button to save data and backup',
'Кнопка сохранения данных и резервного копирования',
'Кнопка збереження даних та резервного копіювання');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (66,
'Button to restore data from backup. You need to select a folder with saved files',
'Кнопка восстановления данных из резервной копии. При этом необходимо выбрать папку с сохраненными файлами',
'Кнопка відновлення даних з резервної копії. При цьому необхідно вибрати папку з збереженими файлами');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (68,
'If this checkbox is set, the data will also be saved in CSV format. If the checkbox is not set, the data will be saved in the bikelog_main.db database file',
'Если установлен данный флажок, данные будут сохраняться также в формате CSV. Если флажок не установлен, данные будут сохраняться в файле базы данных bikelog_main.db',
'Якщо встановлено цей прапорець, дані також будуть збережені в форматі CSV. Якщо прапорець не встановлено, дані будуть збережені в файлі бази даних bikelog_main.db');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (69,
'If this checkbox is set, the data will be restored from CSV format. If the checkbox is not set, the data will be restored from the bikelog_main.db database file. In this case, you need to select a folder with saved files or a file',
'Если установлен данный флажок, данные будут восстанавливаться из формата CSV. Если флажок не установлен, данные будут восстанавливаться из файла базы данных bikelog_main.db. При этом необходимо выбрать папку с сохраненными файлами или файл',
'Якщо встановлено цей прапорець, дані будуть відновлені з формату CSV. Якщо прапорець не встановлено, дані будуть відновлені з файлу бази даних bikelog_main.db. При цьому необхідно вибрати папку зі збереженими файлами або файл');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (72,
'Set the start date, the lower limit of the filter. This will filter the data starting from this date',
'Установите дату начала, нижнюю границу фильтра. При этом будут отфильтрованы данные начиная с этой даты',
'Встановіть дату початку, нижню межу фільтра. При цьому будуть відфільтровані дані, починаючи з цієї дати');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (73,
'Set the end date, the upper limit of the filter. If set, actions will be selected up to and including this date',
'Установите дату верхней границы фильтра. Если она установлена, то действия будут выбраны по эту дату включительно',
'Встановіть дату кінцевої межі фільтра. Якщо встановлено, дії будуть вибрані до цієї дати включно');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (74,
'Set the lower price limit of the filter. If both prices are set, the actions will be selected within these limits',
'Установите нижнюю границу цен фильтра. Если установлены обе цены, то действия будут выбраны в этих границах',
'Встановіть нижню межу цін фільтра. Якщо встановлені обидві ціни, то дії будуть обрані в цих межах');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (75,
'Set the upper price limit of the filter. If both prices are set, the actions will be selected within these limits',
'Установите верхнюю границу цен фильтра. Если установлены обе цены, то действия будут выбраны в этих границах',
'Встановіть верхню межу цін фільтра. Якщо встановлені обидві ціни, то дії будуть обрані в цих межах');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (76,
'The "Clear" button provides a quick and easy way to undo all changes made to the filter if the user wants to start a search from scratch or change the filter criteria',
'Кнопка "Очистить" предоставляет быстрый и простой способ отменить все изменения, внесенные в фильтр, если пользователь хочет начать поиск с чистого листа или изменить критерии фильтрации',
'Кнопка "Очистити" надає швидкий та простий спосіб скасувати всі зміни, внесені до фільтра, якщо користувач хоче почати пошук з чистого аркуша або змінити критерії фільтрації');

INSERT OR REPLACE INTO help (num, en, ru, ua) values (77,
'After the user selects the desired filter parameters (e.g., category, price range, brand, etc.), clicking the "Apply" button activates these settings',
'После того, как пользователь выбрал нужные параметры фильтра (например, категорию, ценовой диапазон, бренд и т.д.), нажатие кнопки "Применить" активирует эти установки',
'Після того, як користувач вибрав потрібні параметри фільтра (наприклад, категорію, ціновий діапазон, бренд тощо), натискання кнопки "Застосувати" активує ці установки');
