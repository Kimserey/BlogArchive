# Extract text from images in F# - OCR'ing my receipts!

Last week [I talked about how I used Deedle to make some basic statistics on my expenses.]() 
Using my bank statements, I showed how to categorize, group, sum and sort expenses so that it would bring a better visibility to my expenses.
Then I thought, actually I should go a level deeper. Instead of checking the transaction as a whole, It would be better to check on the prices of each items I purchased.
Being so lazy, the idea of writing down every expenses was just not considerable. I needed a better way.

__So I thought, why not take a picture of the receipt and detect the text in the picture.__
_At that time, I had never made any research so I wasn't aware that it was already popular._

1. Use Tesseract OCR - .NET
2. Learn from my mistakes
3. Clean the image receipt with ImageMagick and try again
4. Bootup a OWIN selfhost WebSharper Client-Server app

## 1. Use Tesseract OCR - .NET

I had no knowledge about how I would proceed so I googled it.
A quick search came out with high result containing the acronym OCR which stand for _Optical Character Recognition_.
And a library available on .NET is called [Tesseract OCR - .NET](https://github.com/charlesw/tesseract-ocr-dotnet).
__Tesseract__ has some trained machine learning algorithms which detect letter patterns.
It works very well with default fonts as it has already been trained on lots of common fonts and [the training data are available here](https://github.com/tesseract-ocr/tessdata).

To try it, the first thing to do is to to install __Tesseract__ from Nuget.
```
Install-Package Tesseract
```
Get the training data and place it into a [`tessdata`](https://github.com/tesseract-ocr/tessdata/releases/tag/3.04.00) folder which is set to be copied to output.
Using this image:
![]()

And the following code, we can now extract the data from the image:

```
use engine = new TesseractEngine(@"./tessdata", "eng", EngineMode.Default))
use img = Pix.LoadFromFile(__SOURCE_DIRECTORY__ + "/img/original.jpg"))
use page = engine.Process(img)
printfn "%s" (page.GetText())
printfn "Confidence: %.4f" (page.GetMeanConfidence())
```
