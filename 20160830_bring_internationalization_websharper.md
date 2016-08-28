# Bring internationalization (i18n) to your WebSharper webapps in FSharp

When working on webapps which need to be used by international clients, it is important to provide internationalization (i18n).
I18n is the process of developing web/desktop/mobile applications which provide an easy way to change language and culture to be localized to different markets.
For example, English and French markets have different language, date format and number format.
The webapp needs to provide a way to switch texts and respect date and number formats.

So today I will show you how you can bring i18n to your WebSharper webapp. This post is composed by three parts

1. JS libraries
2. WebSharper bindings to work with F#
3. Example

Here is a preview:

![preview](https://raw.githubusercontent.com/Kimserey/InternationalizationSample/master/i18n.gif)

## 1. JS libraries

There are three parts that needs to be configurable in order to provide i18n.
 
  - the language, all text needs to be translated
  - the date format, in some places, the days is after before the months - also days and months need to be translated
  - the number format, some places use dot `.` and others comma `,` to separate decimals - also currencies need to be translated

To provide translation, we will be using i18next [http://i18next.com/](http://i18next.com/) together with the JQuery plugin [https://github.com/i18next/jquery-i18next](https://github.com/i18next/jquery-i18next).
For date format, we will be using Momentjs [http://momentjs.com/](http://momentjs.com/).
And finally for number format, we will be using Numeraljs [http://numeraljs.com/](http://numeraljs.com/).

Let's see first how we can use those libraries in JS before making it available for our F# webapp.

### i18next with JQuery

I18next will be used to provide translation of the text to different languages.
There are two important functions, `i18net.init()` and `i18next.changeLanguage()`.

Here is a simple example:

```
<!DOCTYPE html>
<html>
  <head>
    <script src="bower_components/jquery/dist/jquery.min.js"></script>
    <script src="bower_components/i18next/i18next.js"></script>
    <script src="bower_components/jquery-i18next/jquery-i18next.js"></script>
  </head>

  <body>
    <div>
        <span data-i18n="div.text"></span>
    </div>

    <script>
      i18next.init({
        lng: 'fr',
        resources: {
          en: {
            translation: {
              div: {
                text: 'Hello!'
              }
            }
          },
          fr: {
              translation: {
                  div: {
                      text: 'Bonjour!'
                  }
              }
          }
        }
      }, function(err, t) {
        i18nextJquery.init(i18next, $);
        $('body').localize();
      });
    </script>
  </body>
</html>
```

A configuration is passed to `i18next.init` with default language and the resources containing the languages and translations.
```
{
  "en-GB": {
    translation: {
      div: {
        text: 'Hello!'
      }
    }
  },
  fr: {
      translation: {
          div: {
              text: 'Bonjour!'
          }
      }
  }
}
```
Then we can specify where the translated text will be placed using the attribute `i18next`.
The `i18next.init` takes a callback as second argument which is called when the initialization is done.
We then initialize `i18nextJquery`, the jquery plugin, and after initialized it adds a `localize` function to jquery elements which we can call to apply the translated text `$('body').localize()`.

### Momentjs

To use the localization of momentjs, we need to reference momentjs with the locales.
```
<script src="bower_components/moment/min/moment-with-locales.min.js"></script>
```

To use MomentJs, you only need to use `moment(value)` to transform a JS date to a moment date and use `format()` to format it to a human readable value.
```
moment(value).format(format);
```

When using `format`, Moment will use the current culture set. To change the culture, we must use the `locale` function:
```
moment.locale(language);
```

### Numeraljs

To use the localization of numeraljs, we need to reference the languages.
```
<script src="bower_components/numeral/min/languages.min.js"></script>
```

NumeralJs works the same way as moment.
```
numeral(value).format(format);
```

The only difference is that the function to change language is call `language`:
```
numeral.language(language);
```

### Use the three libraries together

Moment and Numeral are almost the same so we define a common function which translates a value.
```
var translate = function (translator) {
    var $el = translator.el;
    var data = $el.data();

    var value = translator.value(data);
    if(isNull(value)) return;

    var format = translator.format(data);
    if(isNull(format)) return;

    $el.text(translator.execute(value, format));
};
```
The translator provides the jquery element, it provides the underlying value, `moment date` or `numeral number` non formatted, a format defining the format of the data and an `execute` function which translate the value.

The following will be the translate call for momentJS:
```
translate({
    el: $(this),
    value:  function(data) { return data.translateDate; },
    format: function(data) { return data.translateFormat || "YYYY-MM-DD"; },
    execute: function(value, format) {
        return moment(value).format(format);
    }
});
```

and the following will be the translate call for numeralJS:
```
translate({
    el: $(this),
    value:  function(data) { return data.translateNumeric; },
    format: function(data) { return data.translateFormat || "0,0.00"; },
    execute: function(value, format) {
        return numeral(value).format(format);
    }
});
```

To summarize, in order to provide accurate translation, when changing language, we need to:
 1. set the language for i18next, momentjs and numeraljs.
 2. apply the translations using our translate method and the `localize` method added by jquery.

So we will have something like that:
```
var $culture = ... some culture ...

// 1 - Sets Momentjs language
moment.locale($culture);

// 1- Sets numeraljs language
numeral.language($culture);

// 1 - Sets i18next language
i18next.changeLanguage(culture, function(err, t) { 
    
    // 2 - Translates text JQuery
    $('body').localize();

    // 2- Translates dates Momentjs
    $('[data-translate-date]').each(function() {
        translate({
            el: $(this),
            value:  function(data) { return data.translateDate; },
            format: function(data) { return data.translateFormat || "YYYY-MM-DD"; },
            execute: function(value, format) {
                return moment(value).format(format);
            }
        });
    });
        
    // 2- Translates numbers Numeraljs
    $('[data-translate-numeric]').each(function() {
        translate({
            el: $(this),
            value:  function(data) { return data.translateNumeric; },
            format: function(data) { return data.translateFormat || "0,0.00"; },
            execute: function(value, format) {
                return numeral(value).format(format);
            }
        });
    })
});
```

We also defined special jquery attributes which hold original values and format and we use those attributes to access the elements using jquery.

    - data-translate-date
    - data-translate-numeric
    - data-translate-format

Now that we are done with the process in JS, let's see how we can bind it with WebSharper to make it available in F#.

## 2. WebSharper bindings to work with F#

We have defined a good process in JS to translate our text, dates and numbers.
Now we need to provide the translations.
We will do that from WebSharper. 
The benefit for doing this in F# is that we can build a __typesafe__ model which contains all the translations.
So let's define the translation model.

```
type Language = {
    Name: string
    Translation: Translation
}
and Translation = {
    Div: Div
}
and Div = {
    Text: string
}
```

We create a `Language` type which will hold the language name and translation.
The translation will contain all our translation accessible by path.
For example, to access `Text` here we will reference `Div.Text`.

We can now create the WebSharper bindings:

```
[<JavaScript>]
type Localizer =

    [<Direct """
        i18next.init({
            resources: $resources
        }, function(err, t) {
            if(err) {
                console.error("Some unhandled errors occured while initiating i18next.");
            }

            jqueryI18next.init(i18next, $, {
                selectorAttr: 'data-translate'
            });
        });
    """>]
    static member _Init (resources: obj) = X<unit>

    static member Init languages =
        let resources = 
            languages
            |> List.map (fun lg -> lg.Name => New [ "translation" => lg.Translation ])
            |> New

        Localizer._Init resources
    
    [<Direct """
        var isNull = function(key) {
            return !key || typeof key === 'undefined' || key === false;
        };

        var translate = function (translator) {
            var $el = translator.el;
            var data = $el.data();

            var value = translator.value(data);
            if(isNull(value)) return;

            var format = translator.format(data);
            if(isNull(format)) return;

            $el.text(translator.execute(value, format));
        };

        //Sets Momentjs language
        moment.locale($language);

        //Sets numeraljs language
        numeral.language($language);

        //Sets i18next language
        i18next.changeLanguage($language, function(err, t) {
            if(err) {
                console.error("Some unhandled errors occured while changing i18next language to " + $language + ".");
                return;
            }


            //Translates text JQuery
            $('body').localize();
                
            //Translates dates Momentjs
            $('[data-translate-date]').each(function() {
                translate({
                    el: $(this),
                    value:  function(data) { return data.translateDate; },
                    format: function(data) { return data.translateFormat || "YYYY-MM-DD"; },
                    execute: function(value, format) {
                        return moment(value).format(format);
                    }
                });
            });
                
            //Translates numbers Numeraljs
            $('[data-translate-numeric]').each(function() {
                translate({
                    el: $(this),
                    value:  function(data) { return data.translateNumeric; },
                    format: function(data) { return data.translateFormat || "0,0.00"; },
                    execute: function(value, format) {
                        return numeral(value).format(format);
                    }
                });
            })
        });
    """>]
    static member Localize(language: string) = X<unit>
```

We follow the same way we used in JS. 
We create an `initialize` function and a `changeLanguage` which binds directly to the JS equivalent.

Notice the notation `New` and `=>` employed `lg.Name => New [ "translation" => lg.Translation ]`. 
`New` is used to create a `JS object` and `=>` is used to create a property so we can use it together like so: `New [ "propOne" => propOne ; "propTwo"  => propTwo ]`.

Now that we have the bindings, we can use it in a sample.

## 3. Usage example

Let's now see how we can use it in an example. 
The full source code of the sample is available here [https://github.com/Kimserey/InternationalizationSample](https://github.com/Kimserey/InternationalizationSample).

To make our task easier, we can define our templates in `localizer-tpl.html` [https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/localizer-tpl.html](https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/localizer-tpl.html).
```
<span data-template="Text" data-translate="${Text}"></span>
<span data-template="Date" data-translate-date="${date}" data-translate-format="${format}"></span>
<span data-template="Number" data-translate-numeric="${number}" data-translate-format="${format}"></span>
```
Using this templates, we can now construct the elements in a typesafe way and we don't need to bother anymore about the special fields.
Also we need to add the scripts references in the `index.html`.
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" type="text/css" href="Content/InternationalizationSample.css" />
    <script src="bower_components/jquery/dist/jquery.min.js"></script>
    <script src="bower_components/i18next/i18next.js"></script>
    <script src="bower_components/jquery-i18next/jquery-i18next.js"></script>
    <script src="bower_components/moment/min/moment-with-locales.min.js"></script>
    <script src="bower_components/numeral/min/numeral.min.js"></script>
    <script src="bower_components/numeral/min/languages.min.js"></script>
</head>
<body style="margin: 5em">
    <div id="text-test"></div>
    <div id="date-test"></div>
    <div id="number-test"></div>
    <div id="main"></div>
    <script type="text/javascript" src="Content/InternationalizationSample.js"></script>
</body>
</html>
```

And here's a full sample which shows how to use the `Localizer` [https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/Client.fs](https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/Client.fs):
```
namespace InternationalizationSample

open System
open WebSharper
open WebSharper.JavaScript
open WebSharper.JQuery
open WebSharper.UI.Next
open WebSharper.UI.Next.Client
open WebSharper.UI.Next.Html

[<JavaScript>]
module Client =    
    type LocalizerTpl = Templating.Template<"localizer-tpl.html">

    (**
        Provide languages translation
    **)
    let languages =
        [
            { Name = "en-GB"
              Translation = { Div = { Text = "Hello!" } } }

            { Name = "fr"
              Translation = { Div =  { Text = "Bonjour!" } } }
        ]


    let makeTranslationButton code =
        Doc.Button code
            [ attr.style "margin: 1em" ] 
            (fun () -> Localizer.Localize(code))

    let main =

        LocalizerTpl.Text.Doc("Div.Text")
        |> Doc.RunById "text-test"

        LocalizerTpl.Date.Doc(
            date = DateTime.Now.ToString(),
            format = "dddd, MMMM Do YYYY, h:mm:ss a"
        )
        |> Doc.RunById "date-test"
        
        LocalizerTpl.Number.Doc(
            number = "100000000.02",
            format = "$0,0.0"
        )
        |> Doc.RunById "number-test"


        divAttr 
            [ on.afterRender(fun e -> 
                Localizer.Init languages
                Localizer.Localize("en-gb")
              ) ]
            [ makeTranslationButton "en-gb"; makeTranslationButton "fr" ]
        |> Doc.RunById "main"
```

We start by defining our `languages` and its translations.
Then we create a text, a date and a currency formatted number which will be translated.
And finally by using two buttons, one targetted to English and the other one French, we allow the user to translate the content of the website.

And that's it we are done, we now have localization for text language, date and number in our webapp!

![preview](https://raw.githubusercontent.com/Kimserey/InternationalizationSample/master/i18n.gif)

The full source code of the sample is available here [https://github.com/Kimserey/InternationalizationSample](https://github.com/Kimserey/InternationalizationSample).

# Conclusion

Today we saw how we could bring i18n in our WebSharper webapp in F#.
I didn't see many tutorials on how to bring i18n to webapps so I wanted to share a way to do it.
Localization is very important when you need target different markets in different countries.
It is always better to be able to localize and it will also make your webapp more attractive than a Google translated webapp!
Hope you enjoyed reading this post as much as I enjoyed writing it!
As always, if you have comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other post you will like!

 - Understand how to create WebSharper templates - [https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html](https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html)
 - Create a small webapp with WebSharper UI.Next - [https://kimsereyblog.blogspot.co.uk/2016/07/from-idea-to-product-with-websharper-in.html](https://kimsereyblog.blogspot.co.uk/2016/07/from-idea-to-product-with-websharper-in.html)
 - Understand the difference between Direct and Inline - [https://kimsereyblog.blogspot.co.uk/2016/05/understand-difference-between-direct.html](https://kimsereyblog.blogspot.co.uk/2016/05/understand-difference-between-direct.html)
 - The full source code of the sample is available here - [https://github.com/Kimserey/InternationalizationSample](https://github.com/Kimserey/InternationalizationSample).
