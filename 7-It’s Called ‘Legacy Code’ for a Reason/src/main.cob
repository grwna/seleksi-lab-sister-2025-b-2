       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKING.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "input.txt".
           SELECT ACC-FILE ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT TMP-FILE ASSIGN TO "temp.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FILE ASSIGN TO "output.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD IN-FILE.
       01 IN-RECORD             PIC X(22).     *> 10 digits number 
                                               *> Stores upto 2^32 (atleast)

       FD ACC-FILE.
       01 ACC-RECORD-RAW        PIC X(22).

       FD TMP-FILE.
       01 TMP-RECORD            PIC X(22).

       FD OUT-FILE.
       01 OUT-RECORD            PIC X(80).

       WORKING-STORAGE SECTION.
       77 IN-ACCOUNT            PIC 9(6).
       77 IN-ACTION             PIC X(3).
       77 IN-AMOUNT             PIC 9(10)V99.

       77 ACC-ACCOUNT           PIC 9(6).
       77 ACC-ACTION            PIC X(3).
       77 ACC-BALANCE           PIC 9(10)V99.

       77 TMP-BALANCE           PIC 9(10)V99.
       77 IDR-BALANCE           PIC 9(18)V99.
       77 MATCH-FOUND           PIC X VALUE "N".
       77 UPDATED               PIC X VALUE "N".

       77 FORMATTED-AMOUNT      PIC 9(10).99.
       77 BALANCE-TEXT          PIC X(12).
       77 BALANCE-OUT         PIC X(30).          *> stores upto 2^32 * 120.000.000 (atleast)

       
       77 RAI-TO-IDR-RATE    PIC 9(9) VALUE 120000000.
       77 MAX-BALANCE           PIC 9(10)V99 VALUE 9999999999.99.

      * INTEREST
       77 ARGUMENT            PIC X(20).
       77 INTEREST-MODE       PIC X VALUE "N".
           88 INTEREST-MODE-ACTIVE VALUE "Y".
       77 INTEREST-RATE       PIC 9V99999  VALUE 0.00250.
       77 INTEREST-AMOUNT     PIC 9(10)V99.
       77 DISPLAY-BALANCE    PIC ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZ9.99.
       77 DISPLAY-INTEREST   PIC ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZZ,ZZ9.99.

       PROCEDURE DIVISION.
           
       MAIN.
           ACCEPT ARGUMENT FROM COMMAND-LINE.

           IF ARGUMENT = "--apply-interest"
               SET INTEREST-MODE-ACTIVE TO TRUE
           END-IF.

           IF INTEREST-MODE-ACTIVE
               PERFORM APPLY-INTEREST-LOOP
           ELSE
               PERFORM ORIGINAL-MAIN
           END-IF.

           STOP RUN.

       ORIGINAL-MAIN.
           PERFORM READ-INPUT
           PERFORM PROCESS-RECORDS
           IF MATCH-FOUND = "N"
               IF IN-ACTION = "NEW"
                   PERFORM APPEND-ACCOUNT
                   MOVE "ACCOUNT CREATED" TO OUT-RECORD
               ELSE
                   MOVE "ACCOUNT NOT FOUND" TO OUT-RECORD
               END-IF
           END-IF
           PERFORM FINALIZE
           STOP RUN.

       READ-INPUT.
           OPEN INPUT IN-FILE
           READ IN-FILE AT END
               DISPLAY "NO INPUT"
               STOP RUN
           END-READ
           CLOSE IN-FILE

           MOVE IN-RECORD(1:6) TO IN-ACCOUNT
           MOVE IN-RECORD(7:3) TO IN-ACTION
           MOVE FUNCTION NUMVAL(IN-RECORD(10:9)) TO IN-AMOUNT.

       PROCESS-RECORDS.
           OPEN INPUT ACC-FILE
           OPEN OUTPUT TMP-FILE
           PERFORM FOREVER
               READ ACC-FILE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:13))
                           TO ACC-BALANCE
                       IF ACC-ACCOUNT = IN-ACCOUNT
                           MOVE "Y" TO MATCH-FOUND
                           PERFORM APPLY-ACTION
                       ELSE
                           WRITE TMP-RECORD FROM ACC-RECORD-RAW
                       END-IF
           END-PERFORM
           CLOSE ACC-FILE
           CLOSE TMP-FILE.


       APPLY-ACTION.
           MOVE ACC-BALANCE TO TMP-BALANCE
           EVALUATE IN-ACTION
               WHEN "NEW"
                   MOVE "ACCOUNT ALREADY EXISTS" TO OUT-RECORD
               WHEN "DEP"
                   ADD IN-AMOUNT TO TMP-BALANCE
                       ON SIZE ERROR
                            MOVE MAX-BALANCE TO TMP-BALANCE
                   END-ADD
                   MOVE "DEPOSITED MONEY" TO OUT-RECORD
               WHEN "WDR"
                    IF IN-AMOUNT > TMP-BALANCE
                       MOVE "INSUFFICIENT FUNDS" TO OUT-RECORD
                   ELSE
                       SUBTRACT IN-AMOUNT FROM TMP-BALANCE
                       MOVE "WITHDREW MONEY" TO OUT-RECORD
                   END-IF
               WHEN "BAL"
                   MOVE SPACES TO OUT-RECORD
                   MOVE "BALANCE: " TO BALANCE-TEXT
                   COMPUTE IDR-BALANCE = TMP-BALANCE * RAI-TO-IDR-RATE
                   MOVE IDR-BALANCE TO DISPLAY-BALANCE
                   MOVE DISPLAY-BALANCE TO BALANCE-OUT
                   STRING BALANCE-TEXT DELIMITED SIZE
                          "IDR " DELIMITED SIZE
                          FUNCTION TRIM(BALANCE-OUT) DELIMITED SIZE
                          INTO OUT-RECORD
               WHEN OTHER
                   MOVE "UNKNOWN ACTION" TO OUT-RECORD
           END-EVALUATE

           MOVE IN-ACCOUNT TO TMP-RECORD(1:6)
           MOVE IN-ACTION  TO TMP-RECORD(7:3)
           MOVE TMP-BALANCE TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO TMP-RECORD(10:13)

           WRITE TMP-RECORD
           MOVE "Y" TO UPDATED.

       APPEND-ACCOUNT.
           OPEN EXTEND ACC-FILE
           MOVE IN-ACCOUNT TO ACC-RECORD-RAW(1:6)
           MOVE IN-ACTION  TO ACC-RECORD-RAW(7:3)
           MOVE IN-AMOUNT TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO ACC-RECORD-RAW(10:13)

           WRITE ACC-RECORD-RAW
           CLOSE ACC-FILE.

       FINALIZE.
           IF UPDATED = "Y"
               CALL "SYSTEM" USING "cat temp.txt > accounts.txt"
               CALL "SYSTEM" USING "rm temp.txt"
           END-IF
           OPEN OUTPUT OUT-FILE
           WRITE OUT-RECORD
           CLOSE OUT-FILE.

      * INTEREST IMPLEMENTATION
       APPLY-INTEREST-LOOP.
            PERFORM FOREVER
               PERFORM CALCULATE-INTEREST-FOR-ALL-ACCOUNTS
               DISPLAY "Waiting 23 seconds for next cycle..."
               CALL "SYSTEM" USING "sleep 23"
           END-PERFORM.

       CALCULATE-INTEREST-FOR-ALL-ACCOUNTS.
           OPEN INPUT ACC-FILE
           OPEN OUTPUT TMP-FILE

           PERFORM UNTIL 1 = 0
               READ ACC-FILE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:13))
                           TO ACC-BALANCE

                       COMPUTE INTEREST-AMOUNT =
                           ACC-BALANCE * INTEREST-RATE

                       IF ACC-BALANCE NOT = MAX-BALANCE
                           ADD INTEREST-AMOUNT TO ACC-BALANCE
                               ON SIZE ERROR
                                   MOVE MAX-BALANCE TO ACC-BALANCE
                           END-ADD
                       END-IF

                       MOVE ACC-BALANCE TO DISPLAY-BALANCE
                       MOVE INTEREST-AMOUNT TO DISPLAY-INTEREST
                       DISPLAY "Account: " ACC-ACCOUNT
                       DISPLAY " | Interest: " DISPLAY-INTEREST
                       DISPLAY " | New Balance (Rai): " DISPLAY-BALANCE

                       MOVE ACC-ACCOUNT TO TMP-RECORD(1:6)
                       MOVE "INT" TO TMP-RECORD(7:3)
                       MOVE ACC-BALANCE TO FORMATTED-AMOUNT
                       MOVE FORMATTED-AMOUNT TO TMP-RECORD(10:13)

                       WRITE TMP-RECORD
               END-READ
           END-PERFORM

           CLOSE ACC-FILE
           CLOSE TMP-FILE

           CALL "SYSTEM" USING "cp temp.txt accounts.txt"
           DISPLAY "All accounts updated with interest.".
       