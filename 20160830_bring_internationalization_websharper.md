# Bring internationalization (i18n) to your WebSharper webapps in FSharp

When working on webapps which need to be used by international clients, it is important to provide i18n.
I18n is the process of developing applications web/desktop/mobile which provide an easy way to change language and culture to be localized to different markets.
Google translate is not enough to provide a safe and complete translation and adptation to different culures/markets.
For example, the English market has a different language, date format and number format than the French market.
Integrating i18n would mean providing a way to switch between English and French and therefore changed the texts of the webapp from English to French and also respect date and number formats.

So today I will show you how you can bring i18n to your WebSharper webapp. This post is composed by three parts

1. JS libraries
2. WebSharper bindings to work with F#
3. Example

![preview](https://raw.githubusercontent.com/Kimserey/InternationalizationSample/master/i18n.gif)

## 1. JS libraries

There are three parts that needs to be replaced in order to provide i18n.
 
  - the language, all text needs to be translated.
  - the date format, in some places, the days is after before the months
  - the number format, some places use dot `.` and others comma `,` to separate decimals

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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js" ></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/i18next/3.4.1/i18next.min.js" ></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-i18next/0.0.14/i18next-jquery.min.js" ></script>
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
```
Then we can specify where the translated text will be placed using the attribute `i18next`.
The `i18next.init` takes a callback as second argument which is called when the initialization is done.
We then initialize `i18nextJquery`, the jquery plugin, and after initialized it adds a `localize` function to jquery elements which we can call to apply the translated text `$('body').localize()`.

### Momentjs

To use MomentJs, you only need to use `moment(value)` to transform a JS date to a moment date and use `format()` to format it to a human readable value.
```
moment(value).format(format);
```

When using `format`, Moment will use the current culture set. To change the culture, we must use the `locale` function:
```
moment.locale(language);
```

### Numeraljs

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
The translator provides the jquery element, it provides the underlying value, `moment date` or `numeral number` non formated and lastely an `execute` function which translate the value.

The following will be the translate call for momentJS:
```
translate({
    el: $(this),
    value:  function(data) { return data.translateDate; },
    format: function(data) { return data.translateDateFormat || "YYYY-MM-DD"; },
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
    format: function(data) { return data.translateNumericFormat || "0,0.00"; },
    execute: function(value, format) {
        return numeral(value).format(format);
    }
});
```

To summarize, in order to provide accurate translation, when changing language, we need to set the language for i18next, momentjs and numeraljs.
And after the language changed, we can apply the translations.

So we will have something like that:
```
var $culture = ... some culture ...

//Sets Momentjs language
moment.locale($culture);

//Sets numeraljs language
numeral.language($culture);

//Sets i18next language
i18next.changeLanguage(culture, function(err, t) { 
    //Translates text JQuery
    $('body').localize();

    //Translates dates Momentjs
    $('[data-translate-date]').each(function() {
        translate({
            el: $(this),
            value:  function(data) { return data.translateDate; },
            format: function(data) { return data.translateDateFormat || "YYYY-MM-DD"; },
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
            format: function(data) { return data.translateNumericFormat || "0,0.00"; },
            execute: function(value, format) {
                return numeral(value).format(format);
            }
        });
    })
});
```

We also defined special jquery attributes `data-translate-date`, `data-translate-date-format`, `data-translate-numeric`, `data-translate-numeric-format`, which will hold original values for date and number and we use those attributes to access the elements using jquery.
Next instead of having to remember to add the specifix tags, we can create a template for the localized fields.

## 2. WebSharper bindings to work with F#

We have defined a good process in JS to translate our text dates and numbers.
Now we need to provide the translations.

We will do that from WebSharper. The benefit for doing this in F# is that we can build a __typesafe__ model which contains all the translations.
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

After that we can create the WebSharper bindings.

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
                    format: function(data) { return data.translateDateFormat || "YYYY-MM-DD"; },
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
                    format: function(data) { return data.translateNumericFormat || "0,0.00"; },
                    execute: function(value, format) {
                        return numeral(value).format(format);
                    }
                });
            })
        });
    """>]
    static member Localize(language: string) = X<unit>
```

We follow the same way we used the JS.
By creating an initialize function and a change language which binds directly to the JS equivalent.

Notice the notation `New` and `=>` employed `lg.Name => New [ "translation" => lg.Translation ]`. 
`New` is used to create a `JS object` and `=>` is used to create a property so we can use it together like so: `New [ "propOne" => propOne ; "propTwo"  => propTwo ]`.

## 3. Usage example

Let's now see how we can use it in an example. We start first by creating a WebSharper SPA and add a `Localizer` fs.

Then we can define our templates in `localizer-tpl.html` [https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/localizer-tpl.html](https://github.com/Kimserey/InternationalizationSample/blob/master/InternationalizationSample/localizer-tpl.html).
```
<span data-template="Text" data-translate="${Text}"></span>
<span data-template="Date" data-translate-date="${date}" data-translate-date-format="${format}"></span>
<span data-template="Number" data-translate-numeric="${number}" data-translate-numeric-format="${format}"></span>
```
Using this templates, we can now construct the elements in a typesafe way and we don't need to bother anymore about the special fields.
Also we need to add the scripts references in the `index.html`.

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

And that's it we are done, we now have localization for text language, date and number in our webapp!

![preview](https://raw.githubusercontent.com/Kimserey/InternationalizationSample/master/i18n.gif)

# Conclusion

Today we saw how we could support i18n in our WebSharper webapp in F#.
I never saw much tutorial and emphisis on how important it is but we must always remember that not everyone speak or read English and the internet is accessible for everyone.
A webapp allowing user to change languages and cultures will always be better placed than a webapp allowing only English.
We should strive to make our webapp accessbile for everyone without language barriers.
Hope you enjoyed reading this post as much as I enjoyed writing it!
As always, if you have comments leave it here or hit me on Twitter [@Kimserey_Lam](https://twitter.com/Kimserey_Lam). See you next time!

# Other post you will like!

 - Understand how to create WebSharper templates - [https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html](https://kimsereyblog.blogspot.co.uk/2016/08/create-html-componants-for-your.html)
 - Create a small webapp with WebSharper UI.Next - [https://kimsereyblog.blogspot.co.uk/2016/07/from-idea-to-product-with-websharper-in.html](https://kimsereyblog.blogspot.co.uk/2016/07/from-idea-to-product-with-websharper-in.html)
 - Understand the difference between Direct and Inline - [https://kimsereyblog.blogspot.co.uk/2016/05/understand-difference-between-direct.html](https://kimsereyblog.blogspot.co.uk/2016/05/understand-difference-between-direct.html)
