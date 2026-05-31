# Collection Mechanic - Usage Examples

## Example 1: Event Photography Organization

**Scenario**: You're photographing a wedding and want to organize collections by event segments.

**Collection Names to Enter**:
```
Ceremony
Cocktail Hour
Reception - Speeches
Reception - Dancing
Details & Portraits
Couple Portraits
Family Photos
Exit & Sendoff
```

**Expected Result**: 8 collections created, all with valid names (no special characters).

**Process**:
1. Select your wedding root collection set
2. Enter the names above
3. Click Dry Run (all should show "OK")
4. Click Execute
5. Immediately see 8 new collections in Lightroom

---

## Example 2: Product Photography with Sanitization

**Scenario**: You're shooting product photos and have names with slashes and special characters.

**Collection Names to Enter**:
```
Product A: Classic Edition
Product B/Modern Style
"Best Sellers" & Favorites
Q4 2024: Holiday Special
Top <10> Products
Clearance | Final Sale
```

**Dry Run Preview**:
```
Product A: Classic Edition    │ Product_A__Classic_Edition │ MODIFIED
Product B/Modern Style        │ Product_B_Modern_Style     │ MODIFIED
"Best Sellers" & Favorites    │ _Best_Sellers____Favorites │ MODIFIED
Q4 2024: Holiday Special       │ Q4_2024__Holiday_Special   │ MODIFIED
Top <10> Products             │ Top__10__Products          │ MODIFIED
Clearance | Final Sale        │ Clearance___Final_Sale     │ MODIFIED
```

**Process**:
1. Review preview to ensure sanitized names look good
2. If any names look odd, you can close and edit before re-running
3. Click Execute to create with sanitized names

---

## Example 3: Date-Organized Collections

**Scenario**: Create collections for each month of a year.

**Collection Names to Enter**:
```
January 2024
February 2024
March 2024
April 2024
May 2024
June 2024
July 2024
August 2024
September 2024
October 2024
November 2024
December 2024
```

**Process**:
1. Select "2024" collection set as root
2. Enter all 12 months
3. Dry Run (all show "OK" - no special characters)
4. Execute
5. All 12 monthly collections created instantly

---

## Example 4: Complex Naming with Nested Sanitization

**Scenario**: Using complex names that require multiple character replacements.

**Collection Names to Enter**:
```
Before & After: Original
Before & After: Processed
"RAW Files" - Review
"FINAL": Ready for Delivery
Client [ABC Corp] - Session 1
Client [ABC Corp] - Session 2
HD Quality: 1920x1080
4K Quality: 3840x2160
```

**Dry Run Preview**:
```
Before & After: Original           │ Before___After__Original      │ MODIFIED
Before & After: Processed          │ Before___After__Processed     │ MODIFIED
"RAW Files" - Review               │ _RAW_Files_-_Review           │ MODIFIED
"FINAL": Ready for Delivery        │ _FINAL___Ready_for_Delivery   │ MODIFIED
Client [ABC Corp] - Session 1      │ Client__ABC_Corp____Session_1 │ MODIFIED
Client [ABC Corp] - Session 2      │ Client__ABC_Corp____Session_2 │ MODIFIED
HD Quality: 1920x1080              │ HD_Quality__1920x1080         │ MODIFIED
4K Quality: 3840x2160              │ 4K_Quality__3840x2160         │ MODIFIED
```

---

## Example 5: Handling Empty/Invalid Results

**Scenario**: Some entries fail validation.

**Collection Names to Enter**:
```
Valid Collection Name
:::
!!!
Another Valid Name
*/* (all special)
Valid Again
```

**Dry Run Preview**:
```
Valid Collection Name       │ Valid_Collection_Name    │ OK
:::                         │ (empty)                  │ ERROR
!!!                         │ (empty)                  │ ERROR
Another Valid Name          │ Another_Valid_Name       │ OK
*/* (all special)           │ (empty)                  │ ERROR
Valid Again                 │ Valid_Again              │ OK
```

**Process**:
1. Dry Run shows 3 errors (all special characters)
2. You can either:
   - Edit the invalid entries and re-run Dry Run
   - Click Execute to create only the valid ones (4 collections)
3. Navigate back to input and modify entries if needed

---

## Example 6: Whitespace Handling

**Scenario**: Various whitespace scenarios.

**Collection Names to Enter**:
```
  Trimmed Spaces  
Tab	Separated	Items
Normal Name
   
Another After Blank
   Just Spaces   
Final Name
```

**Dry Run Preview**:
```
  Trimmed Spaces        │ Trimmed_Spaces         │ OK
Tab	Separated	Items    │ Tab_Separated_Items    │ MODIFIED (tabs replaced)
Normal Name             │ Normal_Name            │ OK
(empty line skipped)
Another After Blank     │ Another_After_Blank    │ OK
   Just Spaces          │ Just_Spaces            │ OK
Final Name              │ Final_Name             │ OK
```

**Notes**:
- Leading/trailing spaces automatically trimmed
- Empty lines ignored
- Tab characters replaced with underscores
- Results in 6 collections created

---

## Example 7: Workflow - Edit and Retry

**Scenario**: You want to refine names after seeing dry run preview.

**First Attempt - Dry Run**:
```
Original Input:
Client: ABC / DEV
Client: ABC / PROD
Client: ABC / STAGING

Dry Run Preview:
Client__ABC___DEV        │ MODIFIED
Client__ABC___PROD       │ MODIFIED
Client__ABC___STAGING    │ MODIFIED
```

**Observation**: Multiple consecutive underscores - names could be cleaner.

**Edit Input to**:
```
Client-ABC-DEV
Client-ABC-PROD
Client-ABC-STAGING
```

**Second Attempt - Dry Run**:
```
Client-ABC-DEV          │ Client-ABC-DEV        │ OK
Client-ABC-PROD         │ Client-ABC-PROD       │ OK
Client-ABC-STAGING      │ Client-ABC-STAGING    │ OK
```

**Result**: Much cleaner! Now Execute to create.

---

## Example 8: Large Batch Operation

**Scenario**: Creating 50+ collections for a comprehensive archive.

**Collection Names** (excerpt from 50):
```
2024_Q1_Week01
2024_Q1_Week02
2024_Q1_Week03
...
2024_Q4_Week52
Archive_Backup
Archive_Working
Archive_Complete
```

**Process**:
1. Prepare all 50+ names in a text editor
2. Copy/paste into Collection Mechanic
3. Click Dry Run to verify all
4. Click Execute
5. All 50+ collections created in seconds (would take manual clicking for hours)

---

## Tips for Success

1. **Use Consistent Naming**: Pick a pattern and stick with it
   - Good: `Year_Month_Week`, `Client_Project_Phase`
   - Avoid: Random characters, inconsistent separators

2. **Avoid Special Characters**: Use hyphens or underscores instead
   - Instead of: `Client: ABC / DEV`
   - Use: `Client-ABC-DEV`

3. **Use Dry Run**: Always preview before executing
   - Catch unexpected sanitization
   - Verify collection count is correct

4. **Plan Hierarchy**: Decide on collection set structure first
   - Parent set should represent main category
   - Collections under it should be specific items

5. **Test with Small Batch**: Try 5-10 collections first
   - Verify results look correct
   - Then do larger batches

6. **Export Names**: Keep a reference list
   - Useful if you need to recreate structure elsewhere
   - Document any manual naming decisions
