Some notes with `WebSharper.UI.Next`

`m.LensInto (get: 'T -> 'V) (update: 'T -> 'V -> 'T) (key : 'Key) : IRef<'V>`

Used to lens a member of an element of a `ListModel`.

- `get` is used to select the value to lens.
- `update` receives the value of `get` and update the current value of type `T`.
- `key` is the key used to retrieve the value in the `ListModel`

---

Use `Doc.BindView` instead of `View.Map |> Doc.EmbedView`
