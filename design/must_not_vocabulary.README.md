# The `must_not` vocabulary is closed

`must_not_vocabulary.json` is a flat, closed list of lowercase phrases, each of which completes the
sentence "this control **must_not** …". Every interaction rule in `design/patterns/` is phrased with
one of these terms and nothing else, which is what lets a W1b Surface Spec *inherit* a pattern's rules
rather than re-describe them: a spec that says `must_not: navigate on close` means exactly what
`design/patterns/navigation-disclosure-group.md` means by it. Prose advice ("prefer not to navigate on
close") is unenforceable and is not allowed here. The list is deliberately short — a forty-term
vocabulary is a synonym list, a fifteen-term one is a contract — and `test/design/patterns_test.dart`
fails any pattern file that uses a term this file does not contain. **This file is a published
interface: W1b mirrors it at `devflow/schemas/must_not_vocabulary.json`, so adding, renaming or
removing a term is a cross-repo change and must be called out in the objective SUMMARY so the mirror
is updated in the same wave.**
