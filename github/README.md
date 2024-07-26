Github Notes
=========

Notes related to using github and github cli

# Adding directive messages

Use the following syntax in markdown documents (`md` files). 

```markdown
> [!NOTE]  
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]  
> Crucial information necessary for users to succeed.

> [!WARNING]  
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.
```

Ref: https://github.com/orgs/community/discussions/16925
Ref: https://learn.microsoft.com/en-us/contribute/content/markdown-reference#alerts-note-tip-important-caution-warning

> [!WARNING]
> Github markdown syntax for firectives is not portable to other markdown systems which will create a blockquote
> In those scenarios use `:::` block.

