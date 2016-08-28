# Bring internationalization (i18n) to your WebSharper webapps in F#

When working on webapps which need to be used by international clients, it is important to provide i18n.
I18n is the process of developing applications web/desktop/mobile which provide an easy way to change language and culture to be localized to different markets.
For example, the English market has a different language, date format and number format than the French market.
Integrating i18n would mean providing a way to switch between English and French and therefore changed the texts of the webapp from English to French and also respect date and number formats. 

So today I will show you how you can bring i18n to your WebSharper webapp. This post is composed by three parts

1. JS libraries
2. WebSharper bindings
3. Example

## 1. JS libraries

There are three parts that needs to be replaced in order to provide i18n.
 
  - the language, all text needs to be translated.
  - the date format, in some places, the days is after before the months
  - the number format, some places use dot `.` and others comma `,` to separate decimals

To provide translation, we will be using i18next [http://i18next.com/](http://i18next.com/) together with the JQuery plugin [https://github.com/i18next/jquery-i18next](https://github.com/i18next/jquery-i18next).
For date format, we will be using Momentjs [http://momentjs.com/](http://momentjs.com/).
And finally for number format, we will be using Numeraljs [http://numeraljs.com/](http://numeraljs.com/).

### i18next with JQuery

To use i18next, we 

