      *& Apache License
      *===============================================================
      *  Copyright (c) 2008-2018 TEMBO Technology Lab (Pty) Ltd.
      *  Created by AO Foundation - www.adsero-optima.com
      *  Original TEMPLATE author: Tommy Atkins - Chief Development Officer
      *
      *  Licensed under the Apache License, Version 2.0 (the "License");
      *  you may not use this file except in compliance with the License.
      *  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
      *
      *  Unless required by applicable law or agreed to in writing, software
      *  distributed under the License is distributed on an "AS IS" BASIS,
      *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      *  See the License for the specific language governing permissions and
      *  limitations under the License.
      *
      *  The above copyright notice and this permission notice shall be included in all
      *  copies or substantial portions of the Software.
      *
      *                      http://www.adsero-optima.com/
      *& Exported Symbols ============================================
      *   EXPORT SYMBOL(CUSMST@01A)     /* Process "Filter" Request         */
      *===============================================================
     h nomain aut(*use) extbinint(*yes) option(*nodebugio) debug
      *& Copy Books ==================================================
      /copy SRCCPY,ERR03                         Move *DIAG and Resend *ESCAPE Messages
      /copy SRCCPY,ERR11                         Send *ESCAPE Message
      /copy SRCCPY,ERR50                         Convert SQLSTATE to Error Message
      /copy SRCCPY,CMD                           Execute Command - Processor
      *& Prototypes ==================================================
     d*Filter          pr                  extproc('CUSMST@01A')
     d CUSMST@01A      pr
     d ALPHAU          pr                  extproc('DRVSRV@02A')
     d  UIName                       50    const
     d  DBName                       10    const
     d ALPHA           pr                  extproc('DRVSRV@02B')
     d  UIName                       50    const
     d  DBName                       10    const
     d NUMERIC         pr                  extproc('DRVSRV@02C')
     d  UIName                       50    const
     d  DBName                       10    const
     d DATEISO         pr                  extproc('DRVSRV@02D')
     d  UIName                       50    const
     d  DBName                       10    const
      *===============================================================
     d Encode          pr           256    extproc('DRVSRV@02E') varying
     d  Value                       256    options(*varsize)
     d  Length                        5i 0 const
      *===============================================================
     d AddRow          pr
      *& Global Definitions ==========================================
     d CUSMSTFR      e ds                  extname(CUSMSTF) qualified
      *===============================================================
     d SQL$P           s               *   import
     d SQL$            s           4096    varying based(SQL$P)
     d SQLEXE          s           4096
      *===============================================================
     d ODP             s               *   import
     d ODLen           s             10i 0 based(ODP)
     d OutDataP        s               *   import
     d OutData         s           4096    based(OutDataP)
      *===============================================================
     d NoRecs          s             10i 0
      *===============================================================
      *& Procedures ==================================================
      *& Process "Filter" Request >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     p CUSMST@01A      b                   export
      *=====================================================
      /free
       //===================================================
       monitor;
          exec sql set option commit=*none, datfmt=*iso, datsep='-';
          // Create Reusable ODP Control Data Area
          Cmd('CRTDTAARA QTEMP/QSQPSCLS1 TYPE(*CHAR) LEN(1) VALUE()' +
              ' TEXT(''' + 'Reusable ODP Control' + ''')');
       on-error;
       endmon;
       //==================================================
       monitor;
          //================================================
          clear SQL$;
          //================================================
          NUMERIC('CUSTNO':'CUSTNO');
          ALPHAU('RECSTS':'RECSTS');
          ALPHAU('CUSNME':'CUSNME');
          ALPHAU('ADRLN1':'ADRLN1');
          ALPHAU('ADRLN2':'ADRLN2');
          ALPHAU('ADRLN3':'ADRLN3');
          ALPHAU('PSTCDE':'PSTCDE');
          DATEISO('STRDTE':'STRDTE');
          ALPHAU('PHONEN':'PHONEN');
          NUMERIC('REPCDE':'REPCDE');
          ALPHAU('USERID':'USERID');
          //================================================
          if %len(SQL$) = 0;
             SQLEXE = 'SELECT * FROM CUSMSTF ORDER BY CUSTNO';
          else;
             SQLEXE = 'SELECT * FROM CUSMSTF WHERE ' + %trim(SQL$) +
                      ' ORDER BY CUSTNO ';
          endif;
          //================================================
          exec sql prepare CUSMSTF_S from :SQLEXE;
          exec sql declare CUSMSTF_C cursor for CUSMSTF_S;
          exec sql open    CUSMSTF_C;
          //================================================
          clear NoRecs;
          CAPtr = %addr(SQLCA);
          //================================================
          OutData   = '"Rows":[';
          OutDataP += 8;
          //================================================
          dow 0 = 0;
              exec sql fetch next from CUSMSTF_C into :CUSMSTFR;
              if not ERR50(CAPtr);
                 if NoRecs = 0;
                    ERR11('ERR0060':'ERRMSGF');
                 else;
                    leave;
                 endif;
              else;
                 NoRecs += 1;
                 AddRow();
              endif;
          enddo;
          //================================================
          OutData = ']}';
          OutDataP += 2;
          //================================================
          exec sql close CUSMSTF_C;
          //================================================
       on-error;
          ERR03();
       endmon;
      /end-free
      *=====================================================
     p                 e
      *===============================================================
      *& Add Row to Response Data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      *===============================================================
     p AddRow          b
      *=====================================================
      /free
       monitor;
          //================================================
          if NoRecs > 1;
             OutData = ',';
             OutDataP += 1;
          endif;
          //================================================
          OutData = '["'+%char(CUSMSTFR.CUSTNO)+'","'+
                         %trim(CUSMSTFR.RECSTS)+'","'+
                        Encode(CUSMSTFR.CUSNME:30)+'","'+
                        Encode(CUSMSTFR.ADRLN1:30)+'","'+
                        Encode(CUSMSTFR.ADRLN2:30)+'","'+
                        Encode(CUSMSTFR.ADRLN3:30)+'","'+
                        Encode(CUSMSTFR.PSTCDE:5)+'","'+
                         %char(CUSMSTFR.STRDTE:*ISO)+'","'+
                         %trim(CUSMSTFR.PHONEN)+'","'+
                         %char(CUSMSTFR.REPCDE)+'","'+
                         %trim(CUSMSTFR.USERID)+'"]';
          //================================================
          OutDataP += %len(%trim(OutData));
          //================================================
       on-error;
          ERR03();
       endmon;
      /end-free
      *=====================================================
     p                 e
      *===============================================================
