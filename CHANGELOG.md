#  (tag: v1.1.0)

 * 2017-03-28 [2508eca](../../commit/2508eca) - __(vadshalamov)__ Release 1.1.0 
 * 2017-03-28 [5f930e3](../../commit/5f930e3) - __(vadshalamov)__ chore: add rails4 support 
 * 2017-03-27 [01bfe56](../../commit/01bfe56) - __(vadshalamov)__ chore: rm 1.9 & 3.1 support, add auto release 
 * 2017-02-16 [fb5f5a9](../../commit/fb5f5a9) - __(vadshalamov)__ feature: move recreate_queues task from blizko 
https://jira.railsc.ru/browse/BPC-9692
 * 2017-02-16 [a776d82](../../commit/a776d82) - __(vadshalamov)__ fix: add ROOT_LOGGER_DIR to backwards 
https://jira.railsc.ru/browse/SG-5658
 * 2017-02-12 [d9564ae](../../commit/d9564ae) - __(Artem Napolskih)__ feature: redis.keys -> redis.scan when resetting data 

#  (tag: v1.0.1)

 * 2017-02-07 [5480ee1](../../commit/5480ee1) - __(Semyon Pupkov)__ Update CHANGELOG.md 
 * 2017-02-07 [83f611a](../../commit/83f611a) - __(Semyon Pupkov)__ Release 1.0.1 
 * 2017-02-01 [7286ff8](../../commit/7286ff8) - __(Mikhail Nelaev)__ fix: respond_to? doesn't search for protected methods on ruby >= 2 
https://jira.railsc.ru/browse/GOODS-207

#  (tag: v1.0.0)

 * 2017-01-11 [17f9df4](../../commit/17f9df4) - __(Semyon Pupkov)__ Release 1.0.0 
 * 2017-01-11 [b09698b](../../commit/b09698b) - __(Semyon Pupkov)__ chore: freeze nokogiri version for ruby 1.9 
 * 2016-12-20 [2535ec0](../../commit/2535ec0) - __(vadshalamov)__ chore: fix Treasury::Processors::EventDataAccessors tests 
https://jira.railsc.ru/browse/USERS-143

#  (tag: v0.6.0)

 * 2016-12-15 [4114d25](../../commit/4114d25) - __(Semyon Pupkov)__ Release 0.6.0 
 * 2016-12-13 [218eaba](../../commit/218eaba) - __(vadshalamov)__ feature: move ReinitializeObjectJob into gem 
https://jira.railsc.ru/browse/USERS-143
 * 2016-12-13 [fd12ed8](../../commit/fd12ed8) - __(Vadim Shalamov)__ fix: add Models module to backwards (#29) 
https://jira.railsc.ru/browse/USERS-143
 * 2016-12-13 [7b7573f](../../commit/7b7573f) - __(Vadim Shalamov)__ feature: add bge:run task for docker (#27) 
https://jira.railsc.ru/browse/USERS-143
 * 2016-12-12 [304296b](../../commit/304296b) - __(Salahutdinov Dmitry)__ feature: event data readers (#28) 
 * 2016-12-01 [5d625a2](../../commit/5d625a2) - __(vadshalamov)__ feature: move core_demormalization into gem 
https://jira.railsc.ru/browse/USERS-143
 * 2016-11-24 [3adddec](../../commit/3adddec) - __(vadshalamov)__ feature: move bg_executor plugin into gem 
https://jira.railsc.ru/browse/USERS-143
 * 2016-10-26 [48d84fa](../../commit/48d84fa) - __(Semyon Pupkov)__ fix: interesting_event meth should be in base processor 
 * 2016-10-26 [8926025](../../commit/8926025) - __(Semyon Pupkov)__ feature: add methods to user processor form project 
Зачем это надо:
Получается не верное наследование классов
Processor::Base наследуеться от проекта
Processor::User::Base насоелдуется от проекта, а должен от Treasury::Base
и получается теряеться метод object_value который есть только в геме
https://github.com/abak-press/treasury/blob/master/lib/treasury/processors/base.rb#L12
 * 2016-10-26 [4408b20](../../commit/4408b20) - __(Semyon Pupkov)__ chore: add drone, docker and dip 

#  (tag: v0.5.0)

 * 2016-07-22 [fa71f99](../../commit/fa71f99) - __(Semyon Pupkov)__ Release 0.5.0 
 * 2016-07-22 [de5a304](../../commit/de5a304) - __(Semyon Pupkov)__ feature: add denormalization errors 
https://jira.railsc.ru/browse/USERS-50
 * 2016-07-22 [dea3014](../../commit/dea3014) - __(Semyon Pupkov)__ feature: add NoRequireInitialization module 
https://jira.railsc.ru/browse/USERS-50

#  (tag: v0.4.0)

 * 2016-06-28 [bfaf31f](../../commit/bfaf31f) - __(Semyon Pupkov)__ Release 0.4.0 
 * 2016-06-28 [5bacff5](../../commit/5bacff5) - __(vadshalamov)__ feature: add Treasury::LIST_DELIMITER 
USERS-9
 * 2016-06-28 [1c93807](../../commit/1c93807) - __(vadshalamov)__ feature: add db_link_class to new field helper 
USERS-9
 * 2016-06-01 [a314d41](../../commit/a314d41) - __(Semyon Pupkov)__ feature: add helper for create new field in migration 
 * 2016-06-01 [ddfa482](../../commit/ddfa482) - __(vadshalamov)__ feature: generate alias_method 
 * 2016-06-01 [8768c09](../../commit/8768c09) - __(vadshalamov)__ fix tests 
 * 2016-06-01 [dd17b6b](../../commit/dd17b6b) - __(vadshalamov)__ feature: add common extractor 
PC4-17243

#  (tag: v0.3.0)

 * 2016-03-22 [b261c86](../../commit/b261c86) - __(Salahutdinov Dmitry)__ Release 0.3.0 

#  (tag: v0.2.0)

 * 2016-03-11 [d464026](../../commit/d464026) - __(Salahutdinov Dmitry)__ Release 0.2.0 
 * 2016-03-11 [644a080](../../commit/644a080) - __(Sergey Kucher)__ chore: move methods from plugin into gem for processors base - #object - #no_action https://jira.railsc.ru/browse/PC4-15968 
 * 2016-03-10 [9db4360](../../commit/9db4360) - __(Sergey Kucher)__ feature: create manager orders counter - current value and object value for processors base 
https://jira.railsc.ru/browse/PC4-16548
 * 2016-03-02 [2d4cf6f](../../commit/2d4cf6f) - __(Semyon Pupkov)__ chore: use spec_helper instead internal class 

#  (tag: v0.1.0)

 * 2016-03-02 [c21355d](../../commit/c21355d) - __(Semyon Pupkov)__ Release 0.1.0 
 * 2016-03-01 [863782b](../../commit/863782b) - __(Sergey Kucher)__ fix: customer new orders counter - fix treasury/processors/counters module in case when nothing changing 
https://jira.railsc.ru/browse/PC4-16549
 * 2016-03-02 [07aac88](../../commit/07aac88) - __(Semyon Pupkov)__ feature: add helper for stub plugin into tests 

#  (tag: v0.0.5)

 * 2016-03-02 [8475cac](../../commit/8475cac) - __(Salahutdinov Dmitry)__ Release 0.0.5 
 * 2016-03-01 [8375263](../../commit/8375263) - __(Semyon Pupkov)__ feature: add base field and translators 
https://jira.railsc.ru/browse/PC4-16297
 * 2016-02-24 [7e86520](../../commit/7e86520) - __(Sergey Kucher)__ feature: company manager new dialog messages counter - move hash serializer and operations from cosmos-treasury - step for increment/decrement hash values 
https://jira.railsc.ru/browse/PC4-16548

#  (tag: v0.0.4)

 * 2016-02-17 [d16dde0](../../commit/d16dde0) - __(Salahutdinov Dmitry)__ Release 0.0.4 
 * 2016-02-16 [791f5d1](../../commit/791f5d1) - __(Salahutdinov Dmitry)__ feature: базовый счетчик денормализации 
https://jira.railsc.ru/browse/PC4-15968

#  (tag: v0.0.3)

 * 2016-02-16 [b3d0a71](../../commit/b3d0a71) - __(Salahutdinov Dmitry)__ Release 0.0.3 
 * 2016-02-08 [add602d](../../commit/add602d) - __(Sergey Kucher)__ feature: waiting orders count https://jira.railsc.ru/browse/PC4-16549 

#  (tag: v0.0.2)

 * 2015-10-26 [ac186d3](../../commit/ac186d3) - __(Salahutdinov Dmitry)__ Release 0.0.2 
 * 2015-10-22 [bb6ce63](../../commit/bb6ce63) - __(Sergey Kucher)__ add field 'single' and  processor 'counter' pc4-15459 

#  (tag: v0.0.1)

 * 2015-02-25 [2957b41](../../commit/2957b41) - __(Andrew N. Shalaev)__ Release 0.0.1 
 * 2015-02-25 [b39c386](../../commit/b39c386) - __(Andrew N. Shalaev)__ Blank treasury classes 
 * 2015-02-24 [defde40](../../commit/defde40) - __(Mamedaliev Kirill)__ Initial commit 