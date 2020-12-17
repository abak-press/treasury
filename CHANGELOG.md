# v1.9.2

* 2020-12-16 [e21035d](../../commit/e21035d) - __(TamarinEA)__ Release 1.9.2 
* 2020-12-15 [13e399c](../../commit/13e399c) - __(TamarinEA)__ fix: bulk write only similar rows 
https://jira.railsc.ru/browse/GOODS-2638

# v1.9.1

* 2020-08-14 [598d309](../../commit/598d309) - __(Zhidkov Denis)__ fix: type cast strings with negaive integers on hash deserialization 
https://jira.railsc.ru/browse/BPC-17240

# v1.9.0

* 2020-04-23 [51c7d66](../../commit/51c7d66) - __(Andrew N. Shalaev)__ fix: memory optimizations 
https://jira.railsc.ru/browse/BPC-16612

# v1.8.3

* 2020-03-02 [28a30a3](../../commit/28a30a3) - __(Andrew N. Shalaev)__ Release v1.8.2 
* 2020-03-02 [fd07481](../../commit/fd07481) - __(Andrew N. Shalaev)__ fix: fix wrong regular expression for detecting of dates 
https://jira.railsc.ru/browse/BPC-16078

* 2020-03-02 [6a42b9c](../../commit/6a42b9c) - __(Andrew N. Shalaev)__ feature: move to new drone CI 

# v1.8.1

* 2020-02-06 [98522eb](../../commit/98522eb) - __(ZhidkovDenis)__ fix: fixup wrong number of args for ActiveRecord::Base.quote_value in rails >= 4.1 
rails 4.0.x - https://github.com/rails/rails/blob/v4.0.13/activerecord/lib/active_record/sanitization.rb#L6
rails >= 4.1.x - https://github.com/rails/rails/blob/v4.1.16/activerecord/lib/active_record/sanitization.rb#L6

Т.к. все равно вызов делегируется к connection, то заменяем сразу на
connection.quote.

# v1.8.0

* 2020-01-31 [d992baf](../../commit/d992baf) - __(Andrew N. Shalaev)__ fix: type casting for ints and dates 
https://jira.railsc.ru/browse/BPC-16113

* 2019-10-01 [8fd7efe](../../commit/8fd7efe) - __(TamarinEA)__ test: stub class method when check process 
close https://github.com/abak-press/treasury/issues/78

* 2019-10-01 [3dc8094](../../commit/3dc8094) - __(TamarinEA)__ chore: restore pending test 

# v1.7.3

* 2019-10-01 [e2c3b20](../../commit/e2c3b20) - __(TamarinEA)__ chore: lock some gems by ruby version 
* 2019-10-01 [40f04f7](../../commit/40f04f7) - __(TamarinEA)__ chore: remove coding 
* 2019-10-01 [d4c0e25](../../commit/d4c0e25) - __(TamarinEA)__ chore: remove rspec-given 
* 2019-10-01 [89c3dbe](../../commit/89c3dbe) - __(TamarinEA)__ chore: test rails 4.2 

# v1.7.2

* 2019-05-21 [1541ef4](../../commit/1541ef4) - __(Andrew N. Shalaev)__ fix: replace undefined method #to_hash to Hash constructor 

# v1.7.1

* 2019-03-22 [e917963](../../commit/e917963) - __(Andrew N. Shalaev)__ feature: remove support of rails 3.2 

# v1.7.0

* 2018-12-21 [b0d9c1c](../../commit/b0d9c1c) - __(Andrew N. Shalaev)__ fix: reset pid if worker stopped 
* 2018-12-21 [49a3422](../../commit/49a3422) - __(Andrew N. Shalaev)__ feature: support for redis >= v4 

# v1.6.6

* 2018-09-18 [4f2653c](../../commit/4f2653c) - __(Andrew N. Shalaev)__ fix: use AR#clear_active_connections! in rails 4 
https://jira.railsc.ru/browse/BPC-11139

# v1.6.5

* 2018-08-21 [a072bbe](../../commit/a072bbe) - __(TamarinEA)__ fix: use update of columns without nesessary event sort 

# v1.6.4

* 2018-08-08 [aaf96b2](../../commit/aaf96b2) - __(TamarinEA)__ fix: start initialize field when process not alived 

# v1.6.3

* 2018-06-25 [2e34611](../../commit/2e34611) - __(Zhidkov Denis)__ fix: set correct mask to count bg executor instances and clean up pids 

# v1.6.2

* 2018-05-28 [1e14f35](../../commit/1e14f35) - __(Andrew N. Shalaev)__ fix: pgrep should not match with self 
https://jira.railsc.ru/browse/BPC-12530

# v1.6.1

* 2018-05-28 [6c78cf3](../../commit/6c78cf3) - __(Andrew N. Shalaev)__ fix: some typo in code 
* 2018-05-28 [9968c5d](../../commit/9968c5d) - __(Andrew N. Shalaev)__ fix: wrong cmd line format for find pids by pattern 

# v1.6.0

* 2018-03-21 [6e221ce](../../commit/6e221ce) - __(Sergey Kucher)__ chore: Release 1.5.0 
* 2018-03-15 [0d0e6c6](../../commit/0d0e6c6) - __(Sergey Kucher)__ chore: previous company for processors/company/base 
https://jira.railsc.ru/browse/ORDERS-1453

# v1.5.0

* 2018-02-15 [c5cd62c](../../commit/c5cd62c) - __(Vladislav)__ feature(translator): add silence to value_as_integer 
https://jira.railsc.ru/browse/COMM-672

# v1.4.4

* 2017-12-01 [94d18ab](../../commit/94d18ab) - __(Sergey Kucher)__ fix: increase events log payload column size 
https://jira.railsc.ru/browse/ORDERS-1191

# v1.4.3

* 2017-11-15 [dd7a82e](../../commit/dd7a82e) - __(Sergey Kucher)__ fix: logger event time 
https://jira.railsc.ru/browse/ORDERS-967

# v1.4.2

* 2017-11-03 [7797046](../../commit/7797046) - __(Sergey Kucher)__ chore: run load hooks for events logger 
https://jira.railsc.ru/browse/ORDERS-716

# v1.4.1

* 2017-11-02 [46b03be](../../commit/46b03be) - __(Artem Napolskih)__ fix: high cpu load on idle 

# v1.4.0

* 2017-10-20 [a5a9c32](../../commit/a5a9c32) - __(Salahutdinov Dmitry)__ feature: specify intialization batch_size as field parameter 

# v1.3.0

* 2017-10-09 [3c034b4](../../commit/3c034b4) - __(Salahutdinov Dmitry)__ feature: json format for hash serialization 
https://jira.railsc.ru/browse/ORDERS-801

* 2017-09-05 [2ba9923](../../commit/2ba9923) - __(Salahutdinov Dmitry)__ chore: raise error in tests 
* 2017-07-18 [b70df32](../../commit/b70df32) - __(Salahutdinov Dmitry)__ fix: initialization with interval of 1 value 
* 2017-07-14 [70a0a7d](../../commit/70a0a7d) - __(Salahutdinov Dmitry)__ feature: reset value of specified field 
* 2017-07-11 [e3d68ca](../../commit/e3d68ca) - __(Salahutdinov Dmitry)__ feature: do not integerize hash key in hash counters 
https://jira.railsc.ru/browse/ORDERS-658

# v1.2.1

* 2017-05-03 [972b275](../../commit/972b275) - __(pold)__ fix(core): rails 4 compatibility 

# v1.2.0

* 2017-04-25 [c896c72](../../commit/c896c72) - __(Semyon Pupkov)__ chore: use apress-sources version 
* 2017-03-23 [7f2966c](../../commit/7f2966c) - __(Sergey Kucher)__ feature: rspec test case for fields 
https://jira.railsc.ru/browse/ORDERS-589

* 2017-04-19 [91f8ef7](../../commit/91f8ef7) - __(Semyon Pupkov)__ fix: add extractor back for capability 
https://jira.railsc.ru/browse/USERS-244

* 2017-04-17 [570ec1d](../../commit/570ec1d) - __(Semyon Pupkov)__ fix: add raise_no_implemented method to raise treasury error 
https://jira.railsc.ru/browse/USERS-244

* 2017-04-04 [5fc0115](../../commit/5fc0115) - __(Semyon Pupkov)__ refactor: use apress-sources for accessor and extractor 
https://jira.railsc.ru/browse/USERS-244

# v1.1.0

* 2017-03-28 [5f930e3](../../commit/5f930e3) - __(vadshalamov)__ chore: add rails4 support 
* 2017-03-27 [01bfe56](../../commit/01bfe56) - __(vadshalamov)__ chore: rm 1.9 & 3.1 support, add auto release 
* 2017-02-16 [fb5f5a9](../../commit/fb5f5a9) - __(vadshalamov)__ feature: move recreate_queues task from blizko 
https://jira.railsc.ru/browse/BPC-9692

* 2017-02-16 [a776d82](../../commit/a776d82) - __(vadshalamov)__ fix: add ROOT_LOGGER_DIR to backwards 
https://jira.railsc.ru/browse/SG-5658

* 2017-02-12 [d9564ae](../../commit/d9564ae) - __(Artem Napolskih)__ feature: redis.keys -> redis.scan when resetting data 

# v1.0.1

* 2017-02-01 [7286ff8](../../commit/7286ff8) - __(Mikhail Nelaev)__ fix: respond_to? doesn't search for protected methods on ruby >= 2 
https://jira.railsc.ru/browse/GOODS-207

# v1.0.0

* 2017-01-11 [b09698b](../../commit/b09698b) - __(Semyon Pupkov)__ chore: freeze nokogiri version for ruby 1.9 
* 2016-12-20 [2535ec0](../../commit/2535ec0) - __(vadshalamov)__ chore: fix Treasury::Processors::EventDataAccessors tests 
https://jira.railsc.ru/browse/USERS-143

* 2016-12-13 [218eaba](../../commit/218eaba) - __(vadshalamov)__ feature: move ReinitializeObjectJob into gem 
https://jira.railsc.ru/browse/USERS-143

* 2016-12-13 [fd12ed8](../../commit/fd12ed8) - __(Vadim Shalamov)__ fix: add Models module to backwards (#29) 
https://jira.railsc.ru/browse/USERS-143
* 2016-12-13 [7b7573f](../../commit/7b7573f) - __(Vadim Shalamov)__ feature: add bge:run task for docker (#27) 
https://jira.railsc.ru/browse/USERS-143
* 2016-12-01 [5d625a2](../../commit/5d625a2) - __(vadshalamov)__ feature: move core_demormalization into gem 
https://jira.railsc.ru/browse/USERS-143

* 2016-11-24 [3adddec](../../commit/3adddec) - __(vadshalamov)__ feature: move bg_executor plugin into gem 
https://jira.railsc.ru/browse/USERS-143

# v0.6.0

* 2016-12-12 [304296b](../../commit/304296b) - __(Salahutdinov Dmitry)__ feature: event data readers (#28) 
* 2016-10-26 [48d84fa](../../commit/48d84fa) - __(Semyon Pupkov)__ fix: interesting_event meth should be in base processor 
* 2016-10-26 [8926025](../../commit/8926025) - __(Semyon Pupkov)__ feature: add methods to user processor form project 
Зачем это надо:
Получается не верное наследование классов
Processor::Base наследуеться от проекта
Processor::User::Base насоелдуется от проекта, а должен от Treasury::Base
и получается теряеться метод object_value который есть только в геме
https://github.com/abak-press/treasury/blob/master/lib/treasury/processors/base.rb#L12

* 2016-10-26 [4408b20](../../commit/4408b20) - __(Semyon Pupkov)__ chore: add drone, docker and dip 

# v0.5.0

* 2016-07-22 [de5a304](../../commit/de5a304) - __(Semyon Pupkov)__ feature: add denormalization errors 
https://jira.railsc.ru/browse/USERS-50

* 2016-07-22 [dea3014](../../commit/dea3014) - __(Semyon Pupkov)__ feature: add NoRequireInitialization module 
https://jira.railsc.ru/browse/USERS-50

# v0.4.0

* 2016-06-28 [5bacff5](../../commit/5bacff5) - __(vadshalamov)__ feature: add Treasury::LIST_DELIMITER 
USERS-9

* 2016-06-28 [1c93807](../../commit/1c93807) - __(vadshalamov)__ feature: add db_link_class to new field helper 
USERS-9

* 2016-06-01 [a314d41](../../commit/a314d41) - __(Semyon Pupkov)__ feature: add helper for create new field in migration 
* 2016-06-01 [ddfa482](../../commit/ddfa482) - __(vadshalamov)__ feature: generate alias_method 
* 2016-06-01 [8768c09](../../commit/8768c09) - __(vadshalamov)__ fix tests 
* 2016-06-01 [dd17b6b](../../commit/dd17b6b) - __(vadshalamov)__ feature: add common extractor 
PC4-17243

# v0.3.0

* 2016-03-10 [9db4360](../../commit/9db4360) - __(Sergey Kucher)__ feature: create manager orders counter - current value and object value for processors base 
https://jira.railsc.ru/browse/PC4-16548

* 2016-02-24 [7e86520](../../commit/7e86520) - __(Sergey Kucher)__ feature: company manager new dialog messages counter - move hash serializer and operations from cosmos-treasury - step for increment/decrement hash values 
https://jira.railsc.ru/browse/PC4-16548

# v0.2.0

* 2016-03-11 [644a080](../../commit/644a080) - __(Sergey Kucher)__ chore: move methods from plugin into gem for processors base - #object - #no_action https://jira.railsc.ru/browse/PC4-15968 
* 2016-03-02 [2d4cf6f](../../commit/2d4cf6f) - __(Semyon Pupkov)__ chore: use spec_helper instead internal class 

# v0.1.0

* 2016-03-01 [863782b](../../commit/863782b) - __(Sergey Kucher)__ fix: customer new orders counter - fix treasury/processors/counters module in case when nothing changing 
https://jira.railsc.ru/browse/PC4-16549

* 2016-03-02 [07aac88](../../commit/07aac88) - __(Semyon Pupkov)__ feature: add helper for stub plugin into tests 

# v0.0.5

* 2016-03-01 [8375263](../../commit/8375263) - __(Semyon Pupkov)__ feature: add base field and translators 
https://jira.railsc.ru/browse/PC4-16297

# v0.0.4

* 2016-02-16 [791f5d1](../../commit/791f5d1) - __(Salahutdinov Dmitry)__ feature: базовый счетчик денормализации 
https://jira.railsc.ru/browse/PC4-15968

# v0.0.3

* 2016-02-08 [add602d](../../commit/add602d) - __(Sergey Kucher)__ feature: waiting orders count https://jira.railsc.ru/browse/PC4-16549 

# v0.0.2

* 2015-10-22 [bb6ce63](../../commit/bb6ce63) - __(Sergey Kucher)__ add field 'single' and  processor 'counter' pc4-15459 

# v0.0.1

* 2015-02-25 [b39c386](../../commit/b39c386) - __(Andrew N. Shalaev)__ Blank treasury classes 
* 2015-02-24 [defde40](../../commit/defde40) - __(Mamedaliev Kirill)__ Initial commit 
