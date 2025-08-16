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
       01 IN-RECORD             PIC X(24).

       FD ACC-FILE.
       01 ACC-RECORD-RAW        PIC X(24).

       FD TMP-FILE.
       01 TMP-RECORD            PIC X(24).

       FD OUT-FILE.
       01 OUT-RECORD            PIC X(80).

       WORKING-STORAGE SECTION.
       77 IN-ACCOUNT            PIC 9(6).
       77 IN-ACTION             PIC X(3).
       77 IN-AMOUNT             PIC 9(12)V99.

       77 ACC-ACCOUNT           PIC 9(6).
       77 ACC-ACTION            PIC X(3).
       77 ACC-BALANCE           PIC 9(12)V99.

       77 TMP-BALANCE           PIC 9(12)V99.
       77 MATCH-FOUND           PIC X VALUE "N".
       77 UPDATED               PIC X VALUE "N".

       77 FORMATTED-AMOUNT      PIC 9(12).99.
       77 BALANCE-TEXT          PIC X(24).

       77 BALANCE-ALPHA         PIC X(24).
       
      * INTEREST
       77 WS-ARGUMENT            PIC X(20).
       77 WS-INTEREST-MODE       PIC X VALUE "N".
           88 INTEREST-MODE-ACTIVE VALUE "Y".
       77 WS-INTEREST-RATE       PIC 9V999 VALUE 1.500. *> 1.5% rate
       77 WS-INTEREST-AMOUNT     PIC 9(12)V99.
       77 WS-DISPLAY-BALANCE     PIC Z(11)9.99.
       77 WS-DISPLAY-INTEREST    PIC Z(11)9.99.

       PROCEDURE DIVISION.
           
       MAIN.
           ACCEPT WS-ARGUMENT FROM COMMAND-LINE.

           IF WS-ARGUMENT = "--apply-interest"
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
           MOVE FUNCTION NUMVAL(IN-RECORD(10:15)) TO IN-AMOUNT.

       PROCESS-RECORDS.
           OPEN INPUT ACC-FILE
           OPEN OUTPUT TMP-FILE
           PERFORM FOREVER
               READ ACC-FILE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       MOVE ACC-RECORD-RAW(1:6) TO ACC-ACCOUNT
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:15))
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
               WHEN "DEP"
                   ADD IN-AMOUNT TO TMP-BALANCE
                   MOVE "DEPOSITED MONEY" TO OUT-RECORD
               WHEN "WDR"
                   SUBTRACT IN-AMOUNT FROM TMP-BALANCE
                   MOVE "WITHDREW MONEY" TO OUT-RECORD
               WHEN "BAL"
                   MOVE SPACES TO OUT-RECORD
                   MOVE "BALANCE: " TO BALANCE-TEXT
                   MOVE TMP-BALANCE TO FORMATTED-AMOUNT
                   MOVE FORMATTED-AMOUNT TO BALANCE-ALPHA
                   STRING BALANCE-TEXT DELIMITED SIZE
                          BALANCE-ALPHA DELIMITED SIZE
                          INTO OUT-RECORD
               WHEN OTHER
                   MOVE "UNKNOWN ACTION" TO OUT-RECORD
           END-EVALUATE

           MOVE IN-ACCOUNT TO TMP-RECORD(1:6)
           MOVE IN-ACTION  TO TMP-RECORD(7:3)
           MOVE TMP-BALANCE TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO TMP-RECORD(10:15)

           WRITE TMP-RECORD
           MOVE "Y" TO UPDATED.

       APPEND-ACCOUNT.
           OPEN EXTEND ACC-FILE
           MOVE IN-ACCOUNT TO ACC-RECORD-RAW(1:6)
           MOVE IN-ACTION  TO ACC-RECORD-RAW(7:3)
           MOVE IN-AMOUNT TO FORMATTED-AMOUNT
           MOVE FORMATTED-AMOUNT TO ACC-RECORD-RAW(10:15)

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
               DISPLAY "Menunggu 23 detik sebelum siklus berikutnya..."
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
                       MOVE FUNCTION NUMVAL(ACC-RECORD-RAW(10:15))
                           TO ACC-BALANCE

                       COMPUTE WS-INTEREST-AMOUNT =
                           ACC-BALANCE * WS-INTEREST-RATE / 100

                       ADD WS-INTEREST-AMOUNT TO ACC-BALANCE

                       MOVE ACC-BALANCE TO WS-DISPLAY-BALANCE
                       MOVE WS-INTEREST-AMOUNT TO WS-DISPLAY-INTEREST
                       DISPLAY "Akun: " ACC-ACCOUNT
                               " | Bunga: " WS-DISPLAY-INTEREST
                               " | Saldo Baru: " WS-DISPLAY-BALANCE

                       MOVE ACC-ACCOUNT TO TMP-RECORD(1:6)
                       MOVE "INT" TO TMP-RECORD(7:3)
                       MOVE ACC-BALANCE TO FORMATTED-AMOUNT
                       MOVE FORMATTED-AMOUNT TO TMP-RECORD(10:15)

                       WRITE TMP-RECORD
               END-READ
           END-PERFORM

           CLOSE ACC-FILE
           CLOSE TMP-FILE

           CALL "SYSTEM" USING "cp temp.txt accounts.txt"
           DISPLAY "Semua akun telah diupdate dengan bunga.".
       