# ASC_NTS.DOC - FDA FAERS Quarterly Data Extract (QDE)

> Full text extraction from `ASC_NTS.pdf`, preserving original layout as much as possible. Use this as a faithful Markdown reference for Codex.


---

## Page 1

```text
                            "ASC_NTS.DOC" FILE FOR THE
                      QUARTERLY DATA EXTRACT (QDE) FROM THE
                    FDA ADVERSE EVENT REPORTING SYSTEM (FAERS)

                      U.S. FOOD AND DRUG ADMINISTRATION (FDA)
                  CENTER FOR DRUG EVALUATION AND RESEARCH (CDER)
                  OFFICE OF SURVEILLANCE AND EPIDEMIOLOGY (OSE)

                            LAST REVISED: April 2015


TABLE OF CONTENTS

A. INTRODUCTION
B. FILE DESCRIPTIONS
C. DATA ELEMENT DESCRIPTIONS
D. DATA ELEMENT CONTENTS AND MAXIMUM LENGTHS
E. END NOTES
F. LEGACY AERS VS. FDA AERS ASCII TAG COMPARISON TABLES
G. REVISION HISTORY


A. INTRODUCTION

The ASCII data files are '$' delimited; that is, a '$' separates the data
fields. You can import these files into SAS, MS Access or other database
programs. (Some data files, such as DRUGyyQq and REACyyQq, will exceed the
maximum number of records that can be imported into spreadsheet programs such
as MS Excel.)

In the ASCII format, file names have the format <file-descriptor>yyQq, where
<file-descriptor> is a 4-letter abbreviation for the data source, 'yy' is a
2-digit identifier for the year, 'Q' is the letter Q, and 'q' is a 1-digit
identifier for the quarter. As an example, DEMO12Q4 represents demographic
file for the 4th quarter of 2012.

The set of seven ASCII data files in each extract contains data for the full
quarter covered by the extract.


B. FILE DESCRIPTIONS

ASCII Data Files:
----------------
1. DEMOyyQq.TXT contains patient demographic and administrative information,
a single record for each event report.

2. DRUGyyQq.TXT contains drug/biologic information for as many medications as
were reported for the event (1 or more per event).

3. REACyyQq.TXT contains all "Medical Dictionary for Regulatory Activities"
(MedDRA) terms coded for the adverse event (1 or more). For more information
on MedDRA, please contact the MSSO Help Desk at mssohelp@meddra.org. The
website is www.meddra.org.

4. OUTCyyQq.TXT contains patient outcomes for the event (0 or more).



                                     1
```


---

## Page 2

```text
5. RPSRyyQq.TXT contains report sources for the event (0 or more).

6. THERyyQq.TXT contains drug therapy start dates and end dates for the
reported drugs (0 or more per drug per event).

7. INDIyyQq.TXT contains all "Medical Dictionary for Regulatory Activities"
(MedDRA) terms coded for the indications for use (diagnoses) for the reported
drugs (0 or more per drug per event).


ASCII Informational Files:
-------------------------
1. ASC_NTS.DOC, which you are reading, shows in some detail the organization
and content of the ASCII data files.

2. STATyyQq.TXT gives null (that is, no data) counts and frequency counts for
selected fields in the ASCII data sets. (The frequency counts also include
the number of null values; however, the percentages shown are for non-null
values only.)


C. DATA ELEMENT DESCRIPTIONS
1) DEMOGRAPHIC file (DEMOyyQq.TXT)
       Name                                  Description

                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
    PRIMARYID       31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.

      CASEID        Number for identifying a FAERS case.

                    Safety Report Version Number. The Initial Case will be
   CASEVERSION      version 1;   follow-ups to the case will have sequentially
                    incremented version   numbers (for example, 2, 3, 4, etc.).

                    Code for initial or follow-up status of report, as reported
                    by manufacturer.

     I_F_COD        CODE   MEANING_TEXT
                    ----   ------------
                     I      Initial
                     F      Follow-up

                    Date the adverse event occurred or began. (YYYYMMDD format) –
     EVENT_DT       If a complete date is not available, a partial date is
                    provided. See the   NOTE on dates at the end of this section.


                    Date manufacturer first received initial information. In
                    subsequent   versions of a case, the latest manufacturer
      MFR_DT        received date will be   provided (YYYYMMDD format). If a
                    complete date is not available, a   partial date will be
                    provided. See the NOTE on dates at the end of   this section.




                                     2
```


---

## Page 3

```text
1) DEMOGRAPHIC file (DEMOyyQq.TXT)
       Name                                    Description
                    Date FDA received first version (Initial) of Case (YYYYMMDD
   INIT_FDA_DT
                    format)
                    Date FDA received Case. In subsequent versions of a case, the
      FDA_DT        latest   manufacturer received date will be provided
                    (YYYYMMDD format).
                    Code for the type of report submitted (See table below) Also,
                    see Section E, End Note below.

                    CODE        MEANING_TEXT
     REPT_COD       ----       ---------------
                    EXP         Expedited (15-Day)
                    PER         Periodic (Non-Expedited)
                    DIR         Direct

                    Regulatory Authority’s case report number, when available.
     AUTH_NUM
                    +
                     New tag added in 2014Q3 extract.
     MFR_NUM        Manufacturer's unique report identifier.

                    Coded name of manufacturer sending report; if not found, then
     MFR_SNDR
                    verbatim name of organization sending report.
                    Literature Reference information, when available; populated
                    with last 500 characters if >500 characters are available.
     LIT_REF
                    +
                     New tag added in 2014Q3 extract.
       AGE          Numeric value of patient's age at event.
                    Unit abbreviation for patient's age (See table below)

                    CODE      MEANING_TEXT
                    ----      ------------
                    DEC       DECADE
     AGE_COD
                    YR        YEAR
                    MON       MONTH
                    WK        WEEK
                    DY        DAY
                    HR        HOUR
                    Patient Age Group code as follows, when available:

                    CODE     MEANING_TEXT
                    ----     ------------
                     N        Neonate
                     I        Infant
     AGE_GRP
                     C        Child
                     T        Adolescent
                     A        Adult
                     E        Elderly
                    +
                        New tag added in 2014Q3 extract.




                                      3
```


---

## Page 4

```text
1) DEMOGRAPHIC file (DEMOyyQq.TXT)
       Name                                  Description
                    Code for patient's sex (See table below)

                    CODE      MEANING_TEXT
       SEX          ----      ------------
                    UNK       Unknown
                    M         Male
                    F         Female
                    Whether (Y/N) this report was submitted under the electronic
      E_SUB
                    submissions procedure for manufacturers.
        WT          Numeric value of patient's weight.
                    Unit abbreviation for patient's weight (See table below)

                    CODE      MEANING_TEXT
      WT_COD        ----      ------------
                    KG        Kilograms
                    LBS       Pounds
                    GMS       Grams

                    Date report was sent (YYYYMMDD format). If a complete date is
     REPT_DT        not   available, a partial date is provided. See the NOTE on
                    dates at the   end of this section.

                    Whether (Y/N) voluntary reporter also notified manufacturer
      TO_MFR
                    (blank   for manufacturer reports).
                    Abbreviation for the reporter's type of occupation in the
                    latest    version of a case.

                    CODE      MEANING_TEXT
                    ----      ------------
     OCCP_COD
                    MD        Physician
                    PH        Pharmacist
                    OT        Other health-professional
                    LW        Lawyer
                    CN        Consumer

                    The country of the reporter in the latest version of a case:

                    NOTE: Country codes are available per the links below.
 REPORTER_COUNTRY
                    http://estri.ich.org/icsr/ICH_ICSR_Specification_V2-3.pdf
                    http://www.iso.org/iso/home/standards/country_codes/iso-3166-
                    1_decoding_table.htm

   OCCR_COUNTRY     The country where the event occurred.




2) DRUG file (DRUGyyQq.TXT)
       Name                                  Description




                                     4
```


---

## Page 5

```text
2) DRUG file (DRUGyyQq.TXT)
      Name                                   Description
    PRIMARYID       Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
                    31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.
      CASEID        Number for identifying a FAERS case.
     DRUG_SEQ       Unique number for identifying a drug for a Case. To link to
                    the
                    THERyyQq.TXT data file, both the Case number (primary key)
                    and the   DRUG_SEQ number (secondary key) are needed. (For an
                    explanation of   the DRUG_SEQ number, including an example,
                    please see Section E, End   Note 2, below.)
     ROLE_COD       Code for drug's reported role in event(See table below)

                    CODE      MEANING_TEXT
                    ----      ------------
                    PS        Primary Suspect Drug
                    SS        Secondary Suspect Drug
                    C         Concomitant
                    I         Interacting
     DRUGNAME       Name of medicinal product. If a "Valid Trade Name" is
                    populated for   this Case, then DRUGNAME = Valid Trade Name;
                    if not, then DRUGNAME = "Verbatim" name, exactly as entered
                    on the report.
     PROD_AI        Product Active Ingredient, when available.
                    +
                     New tag added in 2014Q3 extract.
     VAL_VBM        Code for source of DRUGNAME (See table below)

                    CODE      MEANING_TEXT
                    ----      ------------
                     1         Validated trade name used
                     2         Verbatim name used
      ROUTE         The route of drug administration
     DOSE_VBM       Verbatim text for dose, frequency, and route, exactly as
                    entered on report.

   CUM_DOSE_CHR     Cumulative dose to first reaction




                                   5
```


---

## Page 6

```text
2) DRUG file (DRUGyyQq.TXT)
       Name                                  Description
  CUM_DOSE_UNIT     Cumulative dose to first reaction unit

                    CODE        Meaning_Text
                    ----        ------------
                    KG          Kilogram(s)
                    GM          Gram(s)
                    MG          Milligram(s)
                    UG          Microgram(s) (μg)
                    NG          Nanogram(s)
                    PG          Picogram(s)
                    MG/KG       Milligram(s)/Kilogram
                    UG/KG       Microgram(s)/Kilogram (μG/KG)
                    MG/M**2     Milligram(s)/Sq. Meter
                    UG/M**2     Microgram(s)/Sq. Meter (μG/M**2)
                    L           Litre(s)
                    ML          Millilitre(s)
                    UL          Microlitre(s) (μL)
                    BQ          Becquerel(s)
                    GBQ         Gigabecquerel(s)
                    MBQ         Megabecquerel(s)
                    KBQ         Kilobecquerel(s)
                    CI          Curie(s)
                    MCI         Millicurie(s)
                    UCI         Microcurie(s) (μCI)
                    NCI         Nanocurie(s)
                    MOL         Mole(s)
                    MMOL        Millimole(s)
                    UMOL        Micromole(s)
                    IU          International Unit(s)
                    KIU         International Unit*(1000s)
                    MIU         International Unit*(1,000,000s)
                    IU/KG       IU/Kilogram
                    MEQ         Milliequivalent(s)
                    PCT         Percent (%)
                    GTT         Drop(s)
                    DF          Dosage Form

                    NOTE: The list below provides Dose codes which are commonly
                    reported; however, dose codes are not limited to this list
                    and other code values may be present.
      DECHAL        Dechallenge code, indicating if reaction abated when drug
                    therapy was stopped (See table below)

                    CODE      MEANING_TEXT
                    ----      ------------
                    Y         Positive dechallenge
                    N         Negative dechallenge
                    U         Unknown
                    D         Does not apply




                                   6
```


---

## Page 7

```text
2) DRUG file (DRUGyyQq.TXT)
       Name                                  Description
      RECHAL        Rechallenge code, indicating if reaction recurred when drug
                    therapy was restarted (See table below)

                    CODE      MEANING_TEXT
                    ----      ------------
                    Y         Positive rechallenge
                    N         Negative rechallenge
                    U         Unknown
                    D         Does not apply
     LOT_NUM        Lot number of the drug (as reported).
      EXP_DT        Expiration date of the drug. (YYYYMMDD format) - If a
                    complete date   is not available, a partial date is provided,
                    See the NOTE on dates   at the end of this section.
     NDA_NUM        NDA number (numeric only)
     DOSE_AMT       Amount of drug reported
    DOSE_UNIT       Unit of drug dose
    DOSE_FORM       Form of dose reported
                    Code for Frequency

                    CODE Meaning_Text
                    ---- ------------
                     1X   Once or one time
                     BID Twice a day
                     BIW Twice a week
                     HS   At bedtime
                     PRN As needed
                     Q12H Every 12 hours
                     Q2H Every 2 hours
                     Q3H Every 3 hours
                     Q3W Every 3 weeks
                     Q4H Every 4 hours
                     Q5H Every 5 hours
    DOSE_FREQ        Q6H Every 6 hours
                     Q8H Every 8 hours
                     QD   Daily
                     QH   Every hour
                     QID 4 times a day
                     QM   Monthly
                     QOD Every other day
                     QOW Every other week
                     QW   Every week
                     TID 3 times a day
                     TIW 3 times a week
                     UNK Unknown

                    NOTE: The list below provides frequency codes which are
                    commonly reported; however, dose frequency codes are not
                    limited to this list and other code values may be present.




                                   7
```


---

## Page 8

```text
3) REACTION file (REACyyQq.TXT)
       Name                                     Description

                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
    PRIMARYID       31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.

      CASEID        Number for identifying a FAERS case.
                    "Preferred Term"-level medical terminology describing the
                    event, using the Medical Dictionary for Regulatory Activities
                    (MedDRA).
        PT          The order of the terms for a given event does not imply
                    priority. In other words, the first term listed is not
                    necessarily considered   more significant than the last one
                    listed.
                    Drug Recur Action data - populated with reaction/event
                    information (PT) if/when the event reappears upon
   DRUG_REC_ACT     readministration of the drug.
                    +
                        New tag added in 2014Q3 extract.




4) OUTCOME file (OUTCyyQq.TXT)
       Name                                     Description
                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
    PRIMARYID       31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.
      CASEID        Number for identifying a FAERS case.
                    Code for a patient outcome (See table below)

                    CODE         MEANING_TEXT
                    ----         ------------
                    DE           Death
                    LT           Life-Threatening
                    HO           Hospitalization - Initial or Prolonged
                    DS           Disability
     OUTC_COD
                    CA           Congenital Anomaly
                    RI           Required Intervention to Prevent Permanent
                                 Impairment/Damage
                    OT           Other Serious (Important Medical Event)

                    NOTE: The outcome from the latest version of a case is
                    provided. If there is more than one outcome, the codes will
                    be line listed.




                                      8
```


---

## Page 9

```text
5) REPORT SOURCE file (RPSRyyQq.TXT)
        Name                                 Description
                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
     PRIMARYID      31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.
      CASEID        Number for identifying a FAERS case.
                    Code for the source of the report (See table below)

                    CODE        MEANING_TEXT
                    ----        ------------
                    FGN         Foreign
                    SDY         Study
                    LIT         Literature
                    CSM         Consumer
                    HP          Health Professional
     RPSR_COD
                    UF          User Facility
                    CR          Company Representative
                    DT          Distributor
                    OTH         Other

                    NOTE: The source from the latest version of a case is
                    provided. If there is more than one source, the codes will
                    be line listed.




6) THERAPY dates file (THERyyQq.TXT)
       Name                                  Description
                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
    PRIMARYID       31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.
      CASEID        Number for identifying a FAERS case.
                    Drug sequence number for identifying a drug for a Case. To
                    link to the DRUGyyQq.TXT data file, both the Case number
   DSG_DRUG_SEQ     primary key) and the DRUG_SEQ number (secondary key) are
                    needed. (For an explanation of the DRUG_SEQ number,
                    including an example, see Section E, End Note 2, below.)
                    Date the therapy was started (or re-started) for this drug
                    (YYYYMMDD) – If a complete date not available, a partial date
     START_DT
                    is provided. See the NOTE on dates at the end of this
                    section.
                    A date therapy was stopped for this drug. (YYYYMMDD) – If a
      END_DT        complete   date not available, a partial date will be
                    provided. See the NOTE on   dates at the end of this section.
       DUR          Numeric value of the duration (length) of therapy



                                   9
```


---

## Page 10

```text
6) THERAPY dates file (THERyyQq.TXT)
       Name                                      Description
                    Unit abbreviation for duration of therapy (see table below)

                    CODE      MEANING TEXT
                    ----      ------------
                    YR        Years
     DUR_COD        MON       Months
                    WK        Weeks
                    DAY       Days
                    HR        Hours
                    MIN       Minutes
                    SEC       Seconds




7) INDICATIONS for use file (INDIyyQq.TXT)
       Name                                      Description
                    Unique number for identifying a FAERS report. This is the
                    primary link field (primary key) between data files (example:
    PRIMARYID       31234561). This is a concatenated key of Case ID and Case
                    Version Number. It is the Identifier for the case sequence
                    (version) number as reported by the manufacturer.
      CASEID        Number for identifying a FAERS case.
                    Drug sequence number for identifying a drug for a Case. To
                    link to the DRUGyyQq.TXT data file, both the Case number
  INDI_DRUG_SEQ     (primary key) and the DRUG_SEQ number (secondary key) are
                    needed. (For an explanation of the DRUG_SEQ number,
                    including an example, see Section E, End Note 2, below.)
                    "Preferred Term"-level medical terminology describing the
     INDI_PT        Indication for use, using the Medical Dictionary for
                    Regulatory Activities MedDRA).


NOTE: Date fields will be coded as follows based upon data available in
FAERS:

      year month day (YYYYMMDD)
      year month (YYYYMM)
      year (YYYY)


D. DATA ELEMENT CONTENTS AND MAXIMUM LENGTHS

   DATA               DATA CONTENT           MAX LENGTH
   ELEMENT
   AGE                N (numeric)            12 (including 2 decimal places)
   AGE_COD            A (Alpha)              7
   AGE_GRP            AN (alphanumeric)      15
   AUTH_NUM           AN (alphanumeric)      500



                                     10
```


---

## Page 11

```text
DATA            DATA CONTENT        MAX LENGTH
ELEMENT
CASEID          N (numeric)         500
CASEVERSION     N (numeric)         22
CUM_DOS_UNIT    AN (alphanumeric)   50
CUM_DOSE_CHR    AN (alphanumeric)   15
DECHAL          A (Alpha)           20
DOSE_AMT        AN (alphanumeric)   15
DOSE_FORM       AN (alphanumeric)   50
DOSE_FREQ       AN (alphanumeric)   50
DOSE_UNIT       AN (alphanumeric)   50
DOSE_VBM        AN (alphanumeric)   300
DRUG_REC_ACT    AN (alphanumeric)   500
DRUG_SEQ        N (numeric)         22
DRUGNAME        AN (alphanumeric)   500
PROD_AI         AN (alphanumeric)   500
DSG_DRUG_SEQ    N (numeric)         22
DUR             N (numeric)         150
DUR_COD         A (Alpha)           500
E_SUB           AN (alphanumeric)   1
END_DT          N (or D, date)      8
EVENT_DT        N (or D, date)      8
EXP_DT          N (or D, date)      1000
FDA_DT          N (or D)            8
SEX             A (Alpha)           5
I_F_CODE        AN (alphanumeric)   1
INDI_DRUG_SEQ   N (numeric)         22
INDI_PT         AN (alphanumeric)   1000
INIT_FDA_DT     N (or D)            8
LIT_REF         AN (alphanumeric)   1000
LOT_NUM         AN (alphanumeric)   1000
MFR_DT          N (or D)            8
MFR_NUM         AN (alphanumeric)   500
MFR_SNDR        AN (alphanumeric)   300
NDA_NUM         N (numeric)         100
OCCP_COD        A (Alpha)           300
OCCR_COUNTRY    A (Alpha)           2
OUTC_COD        A (Alpha)           4000
PRIMARYID       N (numeric)         1000
PT              AN (alphanumeric)   500




                               11
```


---

## Page 12

```text
  DATA                DATA CONTENT            MAX LENGTH
  ELEMENT
  RECHAL              A (Alpha)               20
  REPORTER_COUNTRY    A (Alpha)               500
  REPT_COD            A (Alpha)               9
  REPT_DT             N (or D, date)          8
  ROLE_COD            A (Alpha)               22
  ROUTE               A (Alpha)               25
  RPSR_COD            A (Alpha)               32
  START_DT            N (or D, date)          8
  TO_MFR              A (Alpha)               100
  VAL_VBM             N (numeric)             22
  WT                  N (numeric)             14 (including 5 decimal places)
  WT_COD              A (Alpha)               20




E. END NOTES

1    REPT_COD (Demographic file). Expedited (15-day) and Periodic (Non-
Expedited) reports are from manufacturers; "Direct" reports are voluntarily
submitted to the FDA by non-manufacturers.

2    DRUG_SEQ (drug sequence number found in the Drug file, Therapy file, and
Indications file) denotes the relationship between the drug(s) reported for a
Case, the therapy date(s) reported for the drug(s), and the indications
reported for the drug(s).

Consider Case 3078140 version 1, received by the FDA on 12/31/97. The
PRIMARYID for this case is 30781401. Like any Case, it appears once (and
only once) in the Demographic file:

          PRIMARYID
          ---
          30781401

     Four drugs were reported for this Case: Aricept was reported as suspect,
and Estrogens, Prozac, and Synthroid as concomitant. Primaryid 30781401
appears four times in the Drug file, with a different DRUG_SEQ for each drug:

          PRIMARYID     DRUG_SEQ          DRUGNAME
          ---           --------          --------
          30781401       1                Aricept
          30781401       2                Estrogens
          30781401       3                Prozac( Fluoxetine Hydrochloride
          30781401       4                Synthroid (Levothyroxine Sodium)

     Dates of therapy for Aricept were reported as "4/97 to 6/13/97", and
"6/20/97 (ongoing)." Since the drug was started, stopped, then restarted,
there are two entries in the Drug Therapy file. In such a circumstance, the
two entries will have the same PRIMARYID and the same DRUG_SEQ # (or


                                     12
```


---

## Page 13

```text
DSG_DRUG_SEQ number as it is called in the Therapy file - see below). No
therapy dates were reported for the concomitants; therefore, they do not
appear in the Drug Therapy file, which is excerpted as follows:

       PRIMARYID     DSG_DRUG_SEQ #        START_DT        END_DT
       ---           ----------            --------        ------
       30781401       1                    199704          19970613
       30781401       1                    19970620

NOTE: The Drug Seq number is no longer a unique key as was the case in LAERS
QDE. The Drug Seq number simply shows the order of the DRUGNAME within a
unique case. Additionally, the fields labeled DRUG_SEQ, INDI_DRUG_SEQ, and
DSG_DRUG_SEQ in the Drug, Indication, and Therapy files, respectively, all
serve the same purpose of linking the data elements in each individual file
together with the appropriate drug listed in the case using the PRIMARYID.



F. Legacy AERS (LAERS) vs. FDA AERS (FAERS) ASCII Tag Comparison Tables

Note: The changes to the FAERS ASCII Tags are highlighted in yellow and also
contain an asterisk (*). Tags added after the initial FAERS extract contain a
plus (+) and the date add is noted in the tag description in Section C.

           LAERS ASCII Field    FAERS ASCII Field       ASCII File Name
                    ISR               PRIMARYID*             DEMO
                   CASE                CASEID*               DEMO
               FOLL_SEQ                     N/A*             DEMO
                    N/A           CASEVERSION*               DEMO
                I_F_COD                I_F_COD               DEMO
                   IMAGE                    N/A*             DEMO
               EVENT_DT               EVENT_DT               DEMO
                MFR_DT                     MFR_DT            DEMO
                   N/A           INIT_FDA_DATE*              DEMO
                FDA_DT                     FDA_DT            DEMO
               REPT_COD               REPT_COD               DEMO
                                                    +
                   N/A                AUTH_NUM*              DEMO
                MFR_NUM                MFR_NUM               DEMO
               MFR_SNDR               MFR_SNDR               DEMO
                                                    +
                    N/A               LIT_REF*               DEMO
                    AGE                     AGE              DEMO
                AGE_COD                AGE_COD               DEMO
                                                    +
                    N/A               AGE_GRP*               DEMO
               GNDR_COD               GNDR_COD               DEMO
                   E_SUB                   E_SUB             DEMO
                    WT                       WT              DEMO
                WT_COD                     WT_COD            DEMO
                REPT_DT                REPT_DT               DEMO



                                      13
```


---

## Page 14

```text
LAERS ASCII Field   FAERS ASCII Field   ASCII File Name
     TO_MFR                 TO_MFR           DEMO
    OCCP_COD            OCCP_COD             DEMO
    DEATH_DT                 N/A*            DEMO
     CONFID                  N/A*            DEMO
REPORTER_COUNTRY    REPORTER_COUNTRY         DEMO
       N/A            OCCR_COUNTRY*          DEMO
       ISR             PRIMARYID*            DEMO
      CASE               CASEID*             DEMO
    FOLL_SEQ                 N/A*            DEMO
       N/A            CASEVERSION*           DEMO
     I_F_COD            I_F_COD              DEMO
      IMAGE                  N/A*            DEMO
    EVENT_DT            EVENT_DT             DEMO
     MFR_DT                 MFR_DT           DEMO
      N/A            INIT_FDA_DATE*          DEMO
     FDA_DT                 FDA_DT           DEMO
    REPT_COD            REPT_COD             DEMO
     MFR_NUM            MFR_NUM              DEMO
    MFR_SNDR            MFR_SNDR             DEMO
       AGE                   AGE             DEMO
     AGE_COD             AGE_COD             DEMO
    GNDR_COD            GNDR_COD             DEMO
      E_SUB                 E_SUB            DEMO
       WT                     WT             DEMO
     WT_COD                 WT_COD           DEMO
     REPT_DT             REPT_DT             DEMO
     TO_MFR                 TO_MFR           DEMO
    OCCP_COD            OCCP_COD             DEMO
    DEATH_DT                 N/A*            DEMO
     CONFID                  N/A*            DEMO
REPORTER_COUNTRY    REPORTER_COUNTRY         DEMO
       N/A            OCCR_COUNTRY*          DEMO
       ISR             PRIMARYID*            DRUG
      CASE               CASEID*             DRUG
    DRUG_SEQ            DRUG_SEQ             DRUG
    ROLE_COD            ROLE_COD             DRUG
    DRUGNAME            DRUGNAME             DRUG
       N/A              PROD_AI*+            DRUG
    VAL_VBM             VAL_VBM              DRUG
     ROUTE                  ROUTE            DRUG




                       14
```


---

## Page 15

```text
LAERS ASCII Field   FAERS ASCII Field   ASCII File Name
    DOSE_VBM            DOSE_VBM             DRUG
       N/A            CUM_DOSE_CHR*          DRUG
       N/A            CUM_DOS_UNIT*          DRUG
     DECHAL                 DECHAL           DRUG
     RECHAL                 RECHAL           DRUG
     LOT_NUM            LOT_NUM              DRUG
     EXP_DT                 EXP_DT           DRUG
     NDA_NUM            NDA_NUM              DRUG
       N/A              DOSE_AMT*            DRUG
       N/A             DOSE_UNIT*            DRUG
       N/A             DOSE_FORM*            DRUG
       N/A             DOSE_FREQ*            DRUG
       ISR             PRIMARYID*          REACTION
       N/A               CASEID*           REACTION
       PT                     PT           REACTION
      ISR              PRIMARYID*          OUTCOME
      N/A               CASEID*            OUTCOME
    OUTC_COD            OUTC_COD           OUTCOME
      ISR              PRIMARYID*       REPORT SOURCE
      N/A               CASEID*         REPORT SOURCE
    RPSR_COD            RPSR_COD        REPORT SOURCE
      ISR              PRIMARYID*          THERAPY
      N/A               CASEID*            THERAPY
    DRUG_SEQ         DSG_DRUG_SEQ*         THERAPY
    START_DT            START_DT           THERAPY
     END_DT                 END_DT         THERAPY
      DUR                    DUR           THERAPY
    DUR_COD             DUR_COD            THERAPY
      ISR              PRIMARYID*        INDICATIONS
      N/A               CASEID*          INDICATIONS
    DRUG_SEQ         INDI_DRUG_SEQ*      INDICATIONS
    INDI_PT             INDI_PT          INDICATIONS
      ISR              PRIMARYID*            DRUG
      CASE              CASEID*              DRUG
    DRUG_SEQ            DRUG_SEQ             DRUG
    ROLE_COD            ROLE_COD             DRUG
    DRUGNAME            DRUGNAME             DRUG
     VAL_VBM            VAL_VBM              DRUG
      ROUTE                 ROUTE            DRUG
    DOSE_VBM            DOSE_VBM             DRUG




                       15
```


---

## Page 16

```text
LAERS ASCII Field   FAERS ASCII Field    ASCII File Name
       N/A            CUM_DOSE_CHR*           DRUG
       N/A            CUM_DOS_UNIT*           DRUG
     DECHAL                 DECHAL            DRUG
     RECHAL                 RECHAL            DRUG
     LOT_NUM            LOT_NUM               DRUG
     EXP_DT                 EXP_DT            DRUG
     NDA_NUM            NDA_NUM               DRUG
       N/A              DOSE_AMT*             DRUG
       N/A             DOSE_UNIT*             DRUG
       N/A             DOSE_FORM*             DRUG
       N/A             DOSE_FREQ*             DRUG
       ISR             PRIMARYID*           REACTION
       N/A               CASEID*            REACTION
       PT                     PT            REACTION
                                     +
       NA            DRUG_REC_ACT*          REACTION
       ISR             PRIMARYID*           OUTCOME
       N/A              CASEID*             OUTCOME
    OUTC_COD            OUTC_COD            OUTCOME
       ISR             PRIMARYID*        REPORT SOURCE
       N/A              CASEID*          REPORT SOURCE
    RPSR_COD            RPSR_COD         REPORT SOURCE
       ISR             PRIMARYID*           THERAPY
       N/A              CASEID*             THERAPY
    DRUG_SEQ          DSG_DRUG_SEQ*         THERAPY
    START_DT            START_DT            THERAPY
     END_DT                 END_DT          THERAPY
       DUR                   DUR            THERAPY
    DUR_COD             DUR_COD             THERAPY
      ISR              PRIMARYID*         INDICATIONS
      N/A               CASEID*           INDICATIONS
    DRUG_SEQ         INDI_DRUG_SEQ*       INDICATIONS
    INDI_PT             INDI_PT           INDICATIONS




                       16
```


---

## Page 17

```text
G. REVISION HISTORY

August 2013 (QDE 2012Q4)
------------------------
FDA converted from Legacy AERS to the new FDA Adverse Event Reporting System
(FAERS) in September 2012.

Due to the timing of the commissioning of FAERS and work to ensure the new
extract provides the necessary data, this extract will include data for
September 2012 and the 4th Quarter (timeframe from August 28 - December 31,
2012).

The FAERS database introduces various changes to the data and tables due to
the switch from an ISR-based system to a Case/Version-based system. We have
added new data elements to the FAERS QDE, which we will provide in the files
associated with this document. .

For LAERS revision history details, refer to ASCII_NTS.doc files from
previous extracts available at
http://www.fda.gov/Drugs/GuidanceComplianceRegulatoryInformation/Surveillance
/AdverseDrugEffects/ucm083765.htm.


August 2014 (QDE 2013Q4)
------------------------
Medical Dictionary for Regulatory Activities (MedDRA) Contact information was
updated (Section B.3). Additionally, clarification was added in Section C.2
for Code for Frequency (DOSE_FREQ).


October 2014 (QDE 2014Q1)
----------------------
Correction was made in section C.2 to Cumulative dose to first reaction unit
(CUM_DOS_UNIT) list.


April 2015 (QDE 2014Q3)
-----------------------
A number of changes have been implemented with this release:
    Added new field for Authority Number (AUTH_NUM) in Demographic file
      populated with Regulatory Authority’s case report number, when
      available
    Added new field for Literature Reference (LIT_REF) in Demographic file
      populated with Literature Reference information, when available
    Added new field for Age Group (AGE_GRP) field in Demographic file
      populated with Age Group code as follows, when available:
            CODE      MEANING_TEXT
            N          Neonate
            I          Infant
            C          Child
            T          Adolescent
            A          Adult
            E          Elderly
    Added new field for Product Active Ingredient (PROD_AI) in Drug file
      populated with Product Active Ingredient, when available




                                   17
```


---

## Page 18

```text
   Added new field for Drug Recur Action (DRUG_REC_ACT) in Reaction file
    populated with the Reaction/Event information if/when Rechallenge
    equals Y (Positive Rechallenge)
   Modified field header from GNDR_COD to SEX in Demographic file




                                 18
```
