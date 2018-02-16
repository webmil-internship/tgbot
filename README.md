Служба tgb_start_sender.rb по розкладу (config.yml -> schedule:) запускає розсилку з щоденним ключовим словом.
Щоденне ключове слово береться по рандому з словника words. Ключове слово - пара з українського та англійського. Українське для розсилки, англійське для сервісу розпізнавання. Під час розсилки дата і ID слова записується в таблицю tasks.

Служба tgb_start_listener.rb "слухає" повідомлення від учасників. Учасники скидають фото боту. При отриманні фото бот відправляє його на сервіс розпізнавання і отриманий результат записує в таблицю results (ID учасника, дата, слово, тег ідентифікації, точність тега).

rake db:migrate - створення таблиць.

rake db:seed - формування словника.

Правила гри:
- Для реєстрації або поновлення в грі - /start
- Для зупинки участі в грі - /stop
- Сьогоднішнє завдання - /task
- Статистика всіх учасників - /rate
- Ваша статистика - /my
- Для перегляду цих правил - будь-який текст
