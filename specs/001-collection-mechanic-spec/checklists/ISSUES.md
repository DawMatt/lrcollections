# ISSUES TO RESOLVE

## Run 2026/06/04 0815

General

- [ ] No log entries are not being written to the TPG-Collection-Mechanic.log log file.

Main dialog

- Filter
    - [ ] Relabel as Collection Set Filter
- Collection Set field
    - [ ] First entry in collection set selector is an instruction "Select a collection set". It is not selected by default and is only visible when you open the drop down list. It needs to be selected by default or removed.
    - [ ] The collection set selector has entries such as "Select a collection set", and any nested collection set, that contain strings such as "xc2xbb". I believe these are unicode characters that are supposed to make the list values more aesthetic. The list either needs to be configured to support these characters, or the characters replaced with something that will display correctly.
    - [ ] Rename label to "Base Collection Set"
- Collection Names
    - [ ] The collection names text field contains guidance on expected content. Add operating system specific guidance that option + enter (Mac) or alt + enter (Win) must be used when adding additional collections to be created.
- [ ] Execute button generated this stack trace:
```
Yielding is not allowed within a C or metamethod call
    0: global   assert                         - C
    1: upvalue  ?                              - 179812414:752+5
    2: field    wait                           - 179812414:1133+64
    3:          [unnamed]                      - 345274524:76+42
    4:          [unnamed]                      - tail
    5:          [unnamed]                      - tail
    6: field    getCollectionInfo              - 775833618:147+21
    7: method   getName                        - 929831656:124+10
    8:          [unnamed]                      - UI__MainDialog.lua:168
<end>
```
- [ ] Cancel button is still visible in the dialog.
- [ ] OK, Dry Run and Execute buttons are spread across 2 lines in dialog.
