.. _luci-modules-feed:

========================
Добавление feed-a в LuCI
========================

.. contents::

Пример создания приложения
==========================

Непосредственно исходные тексты модуля (application) находятся в папке
**~/astor2/astor2-luci-feed/applications/helloworld/** в корне с LuCI, где
**helloworld/** -- директория модуля.

Структура модуля
----------------

На примере модуля (application) Hello World

::

  helloworld +
             | Makefile
             |
             | luasrc +
                      | controller/helloapp/ hellomodule.lua
                      |
                      | model/cbi/helloapp-hellomodule/ helloworld.lua
                      |
                      | view/helloapp-hellomodule/ helloworld.htm

Содержание Makefile-а
---------------------

Так как модуль содержит только исходный код Lua, то Makefile состоит из::

  include ../../build/config.mk
  include ../../build/module.mk

Controller
----------

В контроллере располагаются управляющие функции (entry-function), которые
регистрируют функции в меню OpenWRT и указывают адресные пути (URL). Для
этого используем функцию entry, которая принимает 4 параметра::

  entry(path, target, title=nil, order=nil)

Параметры **path** и **target** обязательные.

 * **path** -- адресный путь, для указания пути */foo/bar/*, аргумент
   записывается в виде::

     {"foo", "bar"}

 * **target** -- целевое описание действия, которое будет выполнено, когда
   пользователь сделает запрос, перейдя по URL. Существуют предопределённые, 3
   из которых наиболее важные:

   * call -- вызов функции
   * template -- вызов шаблона
   * cbi -- Configuration Bind Interface -- конфигурация связи интерфейса

 * **title** -- определяет название, которое будет отображаться для пользователя
   в меню (опционально)
 * **order** -- номер, который определяет порядок отображения в меню на том же
   уровне (опционально)

cbi()
"""""

Данный модуль использует вызов **cbi()** из
**helloworld/model/cbi/helloapp-hellomodule/helloworld.lua**

Содержимое файла **helloworld/luasrc/controller/helloapp/hellomodule.lua**
Hello World (c cbi)::

  module("luci.controller.helloapp.hellomodule", package.seeall)

  function index()
      entry({"helloworld"},
            cbi("helloapp-hellomodule/helloworld"),
            "Hello World",
            10).dependent=false
  end

call()
""""""

Для вызова функции (call) файл должен содержать следующее::

  module("luci.controller.helloapp.hellomodule", package.seeall)

  function index()
      entry({"helloworld"},
            call("action_tryme"),
            "Hello World",
            10).dependent=false
  end
  
  function action_tryme()
      luci.http.prepare_content("text/plain")
      luci.http.write("Hello World!")
  end

template()
""""""""""

Для вызова шаблона (template) файл должен содержать следующее::

  module("luci.controller.helloapp.hellomodule", package.seeall)

  entry({"helloworld"},
        template("helloapp-hellomodule/helloworld"),
        "Hello world",
        10).dependent=false

Вызов шаблона должен производиться из
**view/helloapp-hellomodule/helloworld.htm**.

Model
-----

CBI модели
""""""""""

CBI модели служат для создания формального интерфейса пользователя и экономии
конфигурационных файлах UCI. В моделях происходит только описание структуры, а
всю остальную работу по генерации XHTML, его проверке и чтению/записи фалов
выполняет LuCI.

Модуль Hello World содержит небольшой файлик
**model/cbi/helloapp-hellomodule/helloworld.lua**, который для примера выводит
краткую информацию о системе, типе процессора и ядре. А так же содержит две
вкладочки, на второй отображается первая строка вывода команды **mount -i**.

Содержимое файла::
  
  -- Configuration Bind Interface (CBI)
  
  require("luci.sys")
  
  m = Map("system", "System", "Simple description")
  m:chain("luci")
  
  s = m:section(TypedSection, "system", "System Properties")
  s.anonymous = true
  s.addremove = false
  
  s:tab("general", "General Settings")
  s:tab("mount", "Mount Info")
  
  -- System Properties
  local system, model, memtotal, memcached, membuffers, memfree = luci.sys.sysinfo()
  
  s:taboption("general", DummyValue, "_system", "System").value = system
  s:taboption("general", DummyValue, "_cpu", "Processor").value = model
  s:taboption("general", DummyValue, "_kernel", "Kernel").value = luci.util.exec("uname -r") or "?"
  
  -- Mount Info 
  foo = luci.util.exec("mount -i")
  
  s:taboption("mount", DummyValue, "_mount", "Mount line 1").value = luci.util.split(foo, "\n")[1]
    
  return m, t

View
----

Во View располагаются шаблоны, содержащие HTML шаблоны и служащие в основном
для вывода текста или изображений. Шаблоны могут так же включать и исходный код
Lua.

Содержимое файла **view/helloapp-hellomodule/helloworld.htm**

::

  <%+header%>
  <h1>Hello World</h1>
  <p>simple text</p>
  <%+footer%>

Пример добавления приложения
============================

Для добавления модуля (application) в виде feed-a для OpenWRT, необходимо
добавить несколько строк в Makefile в папке с LuCI
**contrib/package/luci/Makefile**. В котором уже есть все необходимые
функции для основных типов модулей. Всё, что нужно, так это добавить строчку в
нужный раздел. Для модуля Hello World требуется добавить после определения
функции **Application**:

::

  [...]
  
  ### Applications ###
  define application
      define Package/luci-app-$(1)
          SECTION:=luci
          CATEGORY:=LuCI
          TITLE:=LuCI - Lua Configuration Interface
          URL:=http://luci.subsignal.org/
          MAINTAINER:=LuCI Development Team <luci@lists.subsignal.org>
          SUBMENU:=Applications
          TITLE:=$(if $(2), $(2), LuCI $(1) application)
      DEPENDS:=+luci-mod-admin-core $(3)
  endef
  
  [...]
  
  define Package/luci-app-diag-devinfo/conffiles
      /etc/config/luci_devinfo
  endef
  
  [...]
  
  ### Hello World ###
  $(eval $(call application, helloworld, This is hello world application))

  [...]
