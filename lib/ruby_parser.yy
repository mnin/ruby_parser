# -*- racc -*-

#if V==20
class Ruby20Parser
#elif V==21
class Ruby21Parser
#elif V == 22
class Ruby22Parser
#elif V == 23
class Ruby23Parser
#elif V == 24
class Ruby24Parser
#elif V == 25
class Ruby25Parser
#elif V == 26
class Ruby26Parser
#elif V == 27
class Ruby27Parser
#elif V == 30
class Ruby30Parser
#else
fail "version not specified or supported on code generation"
#endif

token kCLASS kMODULE kDEF kUNDEF kBEGIN kRESCUE kENSURE kEND kIF kUNLESS
      kTHEN kELSIF kELSE kCASE kWHEN kWHILE kUNTIL kFOR kBREAK kNEXT
      kREDO kRETRY kIN kDO kDO_COND kDO_BLOCK kDO_LAMBDA kRETURN kYIELD kSUPER
      kSELF kNIL kTRUE kFALSE kAND kOR kNOT kIF_MOD kUNLESS_MOD kWHILE_MOD
      kUNTIL_MOD kRESCUE_MOD kALIAS kDEFINED klBEGIN klEND k__LINE__
      k__FILE__ k__ENCODING__ tIDENTIFIER tFID tGVAR tIVAR tCONSTANT
      tLABEL tCVAR tNTH_REF tBACK_REF tSTRING_CONTENT tINTEGER tFLOAT
      tREGEXP_END tUPLUS tUMINUS tUMINUS_NUM tPOW tCMP tEQ tEQQ tNEQ
      tGEQ tLEQ tANDOP tOROP tMATCH tNMATCH tDOT tDOT2 tDOT3 tAREF
      tASET tLSHFT tRSHFT tCOLON2 tCOLON3 tOP_ASGN tASSOC tLPAREN
      tLPAREN2 tRPAREN tLPAREN_ARG tLBRACK tLBRACK2 tRBRACK tLBRACE
      tLBRACE_ARG tSTAR tSTAR2 tAMPER tAMPER2 tTILDE tPERCENT tDIVIDE
      tPLUS tMINUS tLT tGT tPIPE tBANG tCARET tLCURLY tRCURLY
      tBACK_REF2 tSYMBEG tSTRING_BEG tXSTRING_BEG tREGEXP_BEG
      tWORDS_BEG tQWORDS_BEG tSTRING_DBEG tSTRING_DVAR tSTRING_END
      tSTRING tSYMBOL tNL tEH tCOLON tCOMMA tSPACE tSEMI tLAMBDA
      tLAMBEG tDSTAR tCHAR tSYMBOLS_BEG tQSYMBOLS_BEG tSTRING_DEND
#if V >= 21
      tRATIONAL tIMAGINARY
#endif
#if V >= 22
      tLABEL_END
#endif
#if V >= 23
       tLONELY
#endif
#if V >= 26
       tBDOT2 tBDOT3
#endif

preclow
  nonassoc tLOWEST
  nonassoc tLBRACE_ARG
  nonassoc kIF_MOD kUNLESS_MOD kWHILE_MOD kUNTIL_MOD
  left     kOR kAND
  right    kNOT
  nonassoc kDEFINED
  right    tEQL tOP_ASGN
  left     kRESCUE_MOD
  right    tEH tCOLON
  nonassoc tDOT2 tDOT3 tBDOT2 tBDOT3
  left     tOROP
  left     tANDOP
  nonassoc tCMP tEQ tEQQ tNEQ tMATCH tNMATCH
  left     tGT tGEQ tLT tLEQ
  left     tPIPE tCARET
  left     tAMPER2
  left     tLSHFT tRSHFT
  left     tPLUS tMINUS
  left     tSTAR2 tDIVIDE tPERCENT # TODO: tSTAR2 -> tMULT
  right    tUMINUS_NUM tUMINUS
  right    tPOW
  right    tBANG tTILDE tUPLUS
prechigh

rule

         program:   {
                      self.lexer.lex_state = EXPR_BEG
                    }
                    top_compstmt
                    {
                      result = new_compstmt val

                      lexer.cond.pop # local_pop
                      lexer.cmdarg.pop
                    }

    top_compstmt: top_stmts opt_terms
                    {
                      stmt, _ = val
                      result = stmt
                    }

       top_stmts: none
                | top_stmt
                | top_stmts terms top_stmt
                    {
                      result = self.block_append val[0], val[2]
                    }
                | error top_stmt

        top_stmt: stmt
                | klBEGIN
                    {
                      if (self.in_def || self.in_single > 0) then
                        debug20 1
                        yyerror "BEGIN in method"
                      end
                      self.env.extend
                    }
                    begin_block
                    {
                      (_, lineno), _, iter = val
                      iter.line lineno

                      (_, preexe,) = iter
                      preexe.line lineno

                      result = iter
                    }

     begin_block: tLCURLY { result = lexer.lineno } top_compstmt tRCURLY
                    {
                      _, line, stmt, _ = val
                      result = new_iter s(:preexe).line(line), 0, stmt
                    }

        bodystmt: compstmt opt_rescue k_else
                    {
                      res = _values[-2]
                      yyerror "else without rescue is useless" unless res
                    }
                    compstmt
                    opt_ensure
                    {
                      body, resc, _, _, els, ens = val

                      result = new_body [body, resc, els, ens]
                    }
                | compstmt opt_rescue opt_ensure
                    {
                      body, resc, ens = val

                      result = new_body [body, resc, nil, ens]
                    }

        compstmt: stmts opt_terms
                    {
                      result = new_compstmt val
                    }

           stmts: none
                | stmt_or_begin # TODO: newline_node ?
                | stmts terms stmt_or_begin
                    {
                      result = self.block_append val[0], val[2]
                    }
                | error stmt
                    {
                      result = val[1]
                      debug20 2, val, result
                    }

   stmt_or_begin: stmt
                | klBEGIN
                    {
                      yyerror "BEGIN is permitted only at toplevel"
                    }
                  begin_block
                    {
                      result = val[2] # wtf?
                    }

            stmt: kALIAS fitem
                    {
                      lexer.lex_state = EXPR_FNAME
                    }
                    fitem
                    {
                      (_, line), lhs, _, rhs = val
                      result = s(:alias, lhs, rhs).line(line).line line
                    }
                | kALIAS tGVAR tGVAR
                    {
                      (_, line), lhs, rhs = val
                      result = s(:valias, lhs.to_sym, rhs.to_sym).line line
                    }
                | kALIAS tGVAR tBACK_REF
                    {
                      (_, line), lhs, rhs = val
                      result = s(:valias, lhs.to_sym, :"$#{rhs}").line line
                    }
                | kALIAS tGVAR tNTH_REF
                    {
                      yyerror "can't make alias for the number variables"
                    }
                | kUNDEF undef_list
                    {
                      result = val[1]
                    }
                | stmt kIF_MOD expr_value
                    {
                      t, _, c = val
                      result = new_if c, t, nil
                    }
                | stmt kUNLESS_MOD expr_value
                    {
                      f, _, c = val
                      result = new_if c, nil, f
                    }
                | stmt kWHILE_MOD expr_value
                    {
                      e, _, c = val
                      result = new_while e, c, true
                    }
                | stmt kUNTIL_MOD expr_value
                    {
                      e, _, c = val
                      result = new_until e, c, true
                    }
                | stmt kRESCUE_MOD stmt
                    {
                      body, _, resbody = val

                      resbody = new_resbody s(:array).line(resbody.line), resbody
                      result = new_rescue body, resbody
                    }
                | klEND tLCURLY compstmt tRCURLY
                    {
                      (_, line), _, stmt, _ = val

                      if (self.in_def || self.in_single > 0) then
                        debug20 3
                        yyerror "END in method; use at_exit"
                      end

                      result = new_iter s(:postexe).line(line), 0, stmt
                    }
                | command_asgn
                | mlhs tEQL command_call
                    {
                      result = new_masgn val[0], val[2], :wrap
                    }
                | lhs tEQL mrhs
                    {
                      lhs, _, rhs = val
                      result = new_assign lhs, s(:svalue, rhs).line(rhs.line)
                    }
#if V == 20
                | mlhs tEQL arg_value
                    {
                      result = new_masgn val[0], val[2], :wrap
                    }
#endif
#if V >= 27
                | mlhs tEQL mrhs_arg kRESCUE_MOD stmt
                    {
                      # unwraps s(:to_ary, rhs)
                      lhs, _, (_, rhs), _, resbody = val

                      resbody = new_resbody s(:array).line(resbody.line), resbody

                      result = new_masgn lhs, new_rescue(rhs, resbody), :wrap
                    }
#endif
#if V == 20
                | mlhs tEQL mrhs
#else
                | mlhs tEQL mrhs_arg
#endif
                    {
                      result = new_masgn val[0], val[2]
                    }
                | expr

    command_asgn: lhs tEQL command_rhs
                    {
                      result = new_assign val[0], val[2]
                    }
                # | lhs tEQL command_asgn
                #     {
                #       result = new_assign val[0], val[2]
                #     }
                | var_lhs tOP_ASGN command_rhs
                    {
                      result = new_op_asgn val
                    }
                | primary_value tLBRACK2 opt_call_args rbracket tOP_ASGN command_rhs
                    {
                      result = new_op_asgn1 val
                    }
                | primary_value call_op tIDENTIFIER tOP_ASGN command_rhs
                    {
                      prim, _, id, opasgn, rhs = val
                      result = s(:op_asgn, prim, rhs, id.to_sym, opasgn.to_sym)
                      if val[1] == '&.'
                        result.sexp_type = :safe_op_asgn
                      end
                      result.line = val[0].line
                    }
                | primary_value call_op tCONSTANT tOP_ASGN command_rhs
                    {
                      result = s(:op_asgn, val[0], val[4], val[2].to_sym, val[3].to_sym)
                      if val[1] == '&.'
                        result.sexp_type = :safe_op_asgn
                      end
                      result.line = val[0].line
                    }
                | primary_value tCOLON2 tCONSTANT tOP_ASGN command_rhs
                    {
                      lhs1, _, lhs2, op, rhs = val

                      result = s(:op_asgn, lhs1, rhs, lhs2.to_sym, op.to_sym)
                    }
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN command_rhs
                    {
                      lhs1, _, lhs2, op, rhs = val

                      result = s(:op_asgn, lhs1, rhs, lhs2.to_sym, op.to_sym)
                    }
                | backref tOP_ASGN command_rhs
                    {
                      self.backref_assign_error val[0]
                    }

     command_rhs: command_call                =tOP_ASGN
                    {
                      expr, = val
                      result = value_expr expr
                    }
#if V >= 24
                | command_call kRESCUE_MOD stmt
                    {
                      expr, (_, line), resbody = val

                      expr = value_expr expr
                      ary  = s(:array).line line
                      result = new_rescue(expr, new_resbody(ary, resbody))
                    }
#endif
                | command_asgn

            expr: command_call
                | expr kAND expr
                    {
                      lhs, _, rhs = val
                      result = logical_op :and, lhs, rhs
                    }
                | expr kOR expr
                    {
                      lhs, _, rhs = val
                      result = logical_op :or, lhs, rhs
                    }
                | kNOT opt_nl expr
                    {
                      (_, line), _, expr = val
                      result = new_call(expr, :"!").line line
                      # REFACTOR: call_uni_op
                    }
                | tBANG command_call
                    {
                      _, cmd = val
                      result = new_call(cmd, :"!").line cmd.line
                      # TODO: fix line number to tBANG... but causes BAD shift/reduce conflict
                      # REFACTOR: call_uni_op -- see parse26.y
                    }
#if V >= 27
                | arg
                    kIN
                    {
                      # TODO? value_expr($1);
                      self.lexer.lex_state = EXPR_BEG|EXPR_LABEL
                      self.lexer.command_start = false
                      result = self.in_kwarg
                      self.in_kwarg = true
                      self.env.extend
                    }
                    p_expr
                    {
                      self.env.unextend

                      expr, _, old_kwarg, pat = val

                      expr = value_expr expr

                      self.in_kwarg = old_kwarg
                      pat_in = new_in pat, nil, nil, expr.line
                      result = new_case expr, pat_in, expr.line
                    }
#endif
                | arg

      expr_value: expr
                    {
                      result = value_expr(val[0])
                    }

   expr_value_do:   {
                      lexer.cond.push true
                    }
                    expr_value do
                    {
                      lexer.cond.pop
                    }
                    {
                      _, expr, _, _ = val
                      result = expr
                    }

    command_call: command
                | block_command

   block_command: block_call
                | block_call call_op2 operation2 command_args
                    {
                      blk, _, msg, args = val
                      result = new_call(blk, msg.to_sym, args).line blk.line
                    }

 cmd_brace_block: tLBRACE_ARG
                    {
                      # self.env.extend(:dynamic)
                      result = self.lexer.lineno
                    }
                    brace_body tRCURLY
                    {
                      _, line, body, _ = val

                      result = body
                      result.line = line

                      # self.env.unextend
                    }

           fcall: operation
                    {
                      msg, = val
                      result = new_call(nil, msg.to_sym).line lexer.lineno
                    }

         command: fcall command_args =tLOWEST
                    {
                      call, args = val
                      result = call.concat args.sexp_body
                    }
                | fcall command_args cmd_brace_block
                    {
                      call, args, block = val

                      result = call.concat args.sexp_body

                      if block then
                        block_dup_check result, block

                        result, operation = block, result
                        result.insert 1, operation
                      end
                    }
                | primary_value call_op operation2 command_args =tLOWEST
                    {
                      lhs, callop, op, args = val
                      result = new_call lhs, op.to_sym, args, callop
                    }
                | primary_value call_op operation2 command_args cmd_brace_block
                    {
                      recv, _, msg, args, block = val
                      call = new_call recv, msg.to_sym, args, val[1]

                      block_dup_check call, block

                      block.insert 1, call
                      result = block
                    }
                | primary_value tCOLON2 operation2 command_args =tLOWEST
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tCOLON2 operation2 command_args cmd_brace_block
                    {
                      recv, _, msg, args, block = val
                      call = new_call recv, msg.to_sym, args

                      block_dup_check call, block

                      block.insert 1, call
                      result = block
                    }
                | kSUPER command_args
                    {
                      result = new_super val[1]
                    }
                | kYIELD command_args
                    {
                      (_, line), args = val
                      result = new_yield args
                      result.line line # TODO: push to new_yield
                    }
                | k_return call_args
                    {
                      line = val[0].last
                      result = s(:return, ret_args(val[1])).line(line)
                    }
                | kBREAK call_args
                    {
                      (_, line), args = val
                      result = s(:break, ret_args(args)).line line
                    }
                | kNEXT call_args
                    {
                      line = val[0].last
                      result = s(:next, ret_args(val[1])).line(line)
                    }

            mlhs: mlhs_basic
                | tLPAREN mlhs_inner rparen
                    {
                      result = val[1]
                    }

      mlhs_inner: mlhs_basic
                | tLPAREN mlhs_inner rparen
                    {
                      _, arg, _ = val
                      l = arg.line

                      result = s(:masgn, s(:array, arg).line(l)).line l
                    }

      mlhs_basic: mlhs_head
                    {
                      head, = val
                      result = s(:masgn, head).line head.line
                    }
                | mlhs_head mlhs_item
                    {
                      lhs, rhs = val
                      result = s(:masgn, lhs << rhs.compact).line lhs.line
                    }
                | mlhs_head tSTAR mlhs_node
                    {
                      head, _, tail = val
                      head << s(:splat, tail).line(tail.line)
                      result = s(:masgn, head).line head.line
                    }
                | mlhs_head tSTAR mlhs_node tCOMMA mlhs_post
                    {
                      ary1, _, splat, _, ary2 = val

                      result = list_append ary1, s(:splat, splat).line(splat.line)
                      result.concat ary2.sexp_body
                      result = s(:masgn, result).line result.line
                    }
                | mlhs_head tSTAR
                    {
                      head, _ = val
                      l = head.line
                      result = s(:masgn, head << s(:splat).line(l)).line l
                    }
                | mlhs_head tSTAR tCOMMA mlhs_post
                    {
                      head, _, _, post = val
                      ary = list_append head, s(:splat).line(head.line)
                      ary.concat post.sexp_body
                      result = s(:masgn, ary).line ary.line
                    }
                | tSTAR mlhs_node
                    {
                      _, node = val
                      l = node.line
                      splat  = s(:splat, node).line l
                      ary    = s(:array, splat).line l
                      result = s(:masgn, ary).line l
                    }
                | tSTAR mlhs_node tCOMMA mlhs_post
                    {
                      _, node, _, post = val

                      splat = s(:splat, node).line node.line
                      ary = s(:array, splat).line splat.line
                      ary.concat post.sexp_body
                      result = s(:masgn, ary).line ary.line
                    }
                | tSTAR
                    {
                      l = lexer.lineno
                      result = s(:masgn, s(:array, s(:splat).line(l)).line(l)).line l
                    }
                | tSTAR tCOMMA mlhs_post
                    {
                      _, _, post = val
                      l = post.line

                      splat = s(:splat).line l
                      ary = s(:array, splat, *post.sexp_body).line l
                      result = s(:masgn, ary).line l
                    }

       mlhs_item: mlhs_node
                | tLPAREN mlhs_inner rparen
                    {
                      result = val[1]
                    }

       mlhs_head: mlhs_item tCOMMA
                    {
                      lhs, _ = val
                      result = s(:array, lhs).line lhs.line
                    }
                | mlhs_head mlhs_item tCOMMA
                    {
                      result = val[0] << val[1].compact
                    }

       mlhs_post: mlhs_item
                    {
                      item, = val
                      result = s(:array, item).line item.line
                    }
                | mlhs_post tCOMMA mlhs_item
                    {
                      result = list_append val[0], val[2]
                    }

       mlhs_node: user_variable
                    {
                      result = self.assignable val[0]
                    }
                | keyword_variable
                    {
                      result = self.assignable val[0]
                    }
                | primary_value tLBRACK2 opt_call_args rbracket
                    {
                      result = self.aryset val[0], val[2]
                    }
                | primary_value call_op tIDENTIFIER
                    {
                      result = new_attrasgn val[0], val[2], val[1]
                    }
                | primary_value tCOLON2 tIDENTIFIER
                    {
                      recv, _, id = val
                      result = new_attrasgn recv, id
                    }
                | primary_value call_op tCONSTANT
                    {
                      result = new_attrasgn val[0], val[2], val[1]
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      if (self.in_def || self.in_single > 0) then
                        debug20 7
                        yyerror "dynamic constant assignment"
                      end

                      expr, _, id = val
                      l = expr.line

                      result = s(:const, s(:colon2, expr, id.to_sym).line(l), nil).line l
                    }
                | tCOLON3 tCONSTANT
                    {
                      if (self.in_def || self.in_single > 0) then
                        debug20 8
                        yyerror "dynamic constant assignment"
                      end

                      _, id = val
                      l = lexer.lineno

                      result = s(:const, nil, s(:colon3, id.to_sym).line(l)).line l
                    }
                | backref
                    {
                      self.backref_assign_error val[0]
                    }

             lhs: user_variable
                    {
                      line = lexer.lineno
                      result = self.assignable val[0]
                      result.line = line
                    }
                | keyword_variable
                    {
                      line = lexer.lineno
                      result = self.assignable val[0]
                      result.line = line
                      debug20 9, val, result
                    }
                | primary_value tLBRACK2 opt_call_args rbracket
                    {
                      lhs, _, args, _ = val
                      result = self.aryset lhs, args
                    }
                | primary_value call_op tIDENTIFIER # REFACTOR
                    {
                      lhs, op, id = val
                      result = new_attrasgn lhs, id, op
                    }
                | primary_value tCOLON2 tIDENTIFIER
                    {
                      lhs, _, id = val
                      result = new_attrasgn lhs, id
                    }
                | primary_value call_op tCONSTANT # REFACTOR?
                    {
                      result = new_attrasgn val[0], val[2], val[1]
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      expr, _, id = val

                      if (self.in_def || self.in_single > 0) then
                        debug20 10
                        yyerror "dynamic constant assignment"
                      end

                      l = expr.line
                      result = s(:const, s(:colon2, expr, id.to_sym).line(l)).line l
                    }
                | tCOLON3 tCONSTANT
                    {
                      _, id = val

                      if (self.in_def || self.in_single > 0) then
                        debug20 11
                        yyerror "dynamic constant assignment"
                      end

                      l = lexer.lineno
                      result = s(:const, s(:colon3, id.to_sym).line(l)).line l
                    }
                | backref
                    {
                      self.backref_assign_error val[0]
                    }

           cname: tIDENTIFIER
                    {
                      yyerror "class/module name must be CONSTANT"
                    }
                | tCONSTANT

           cpath: tCOLON3 cname
                    {
                      _, name = val
                      result = s(:colon3, name.to_sym).line lexer.lineno
                    }
                | cname
                    {
                      result = val[0].to_sym
                    }
                | primary_value tCOLON2 cname
                    {
                      pval, _, name = val

                      result = s(:colon2, pval, name.to_sym)
                      result.line pval.line
                    }

           fname: tIDENTIFIER | tCONSTANT | tFID
                | op
                    {
                      lexer.lex_state = EXPR_END
                      result = val[0]
                    }

                | reswords
                    {
                      (sym, _line), = val
                      result = sym
                    }

           fitem: fname
                    {
                      id, = val
                      result = s(:lit, id.to_sym).line lexer.lineno
                    }
                | symbol

      undef_list: fitem
                    {
                      result = new_undef val[0]
                    }
                |
                    undef_list tCOMMA
                    {
                      lexer.lex_state = EXPR_FNAME
                    }
                    fitem
                    {
                      result = new_undef val[0], val[3]
                    }

                op: tPIPE    | tCARET  | tAMPER2  | tCMP  | tEQ    | tEQQ
                |   tMATCH   | tNMATCH | tGT      | tGEQ  | tLT    | tLEQ
                |   tNEQ     | tLSHFT  | tRSHFT   | tPLUS | tMINUS | tSTAR2
                |   tSTAR    | tDIVIDE | tPERCENT | tPOW  | tDSTAR | tBANG   | tTILDE
                |   tUPLUS   | tUMINUS | tAREF    | tASET | tBACK_REF2

        reswords: k__LINE__ | k__FILE__ | k__ENCODING__ | klBEGIN | klEND
                | kALIAS    | kAND      | kBEGIN        | kBREAK  | kCASE
                | kCLASS    | kDEF      | kDEFINED      | kDO     | kELSE
                | kELSIF    | kEND      | kENSURE       | kFALSE  | kFOR
                | kIN       | kMODULE   | kNEXT         | kNIL    | kNOT
                | kOR       | kREDO     | kRESCUE       | kRETRY  | kRETURN
                | kSELF     | kSUPER    | kTHEN         | kTRUE   | kUNDEF
                | kWHEN     | kYIELD    | kIF           | kUNLESS | kWHILE
                | kUNTIL

             arg: lhs tEQL arg_rhs
                    {
                      result = new_assign val[0], val[2]
                    }
                | var_lhs tOP_ASGN arg_rhs
                    {
                      result = new_op_asgn val
                    }
                | primary_value tLBRACK2 opt_call_args rbracket tOP_ASGN arg_rhs
                    {
                      result = new_op_asgn1 val
                    }
                | primary_value call_op tIDENTIFIER tOP_ASGN arg_rhs
                    {
                      result = new_op_asgn2 val
                    }
                | primary_value call_op tCONSTANT tOP_ASGN arg_rhs
                    {
                      result = new_op_asgn2 val
                    }
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN arg_rhs
                    {
                      lhs, _, id, op, rhs = val

                      result = s(:op_asgn, lhs, rhs, id.to_sym, op.to_sym).line lhs.line
                    }
                | primary_value tCOLON2 tCONSTANT tOP_ASGN arg_rhs
                    {
                      lhs1, _, lhs2, op, rhs = val

                      lhs = s(:colon2, lhs1, lhs2.to_sym).line lhs1.line
                      result = new_const_op_asgn [lhs, op, rhs]
                    }
                | tCOLON3 tCONSTANT
                    {
                      result = self.lexer.lineno
                    }
                    tOP_ASGN arg_rhs
                    {
                      _, lhs, line, op, rhs = val

                      lhs = s(:colon3, lhs.to_sym).line line
                      result = new_const_op_asgn [lhs, op, rhs]
                    }
                | backref tOP_ASGN arg_rhs
                    {
                      # TODO: lhs = var_field val[0]
                      asgn = new_op_asgn val
                      result = self.backref_assign_error asgn
                    }
                | arg tDOT2 arg
                    {
                      v1, v2 = val[0], val[2]
                      if v1.node_type == :lit and v2.node_type == :lit and Integer === v1.last and Integer === v2.last then
                        result = s(:lit, (v1.last)..(v2.last)).line v1.line
                      else
                        result = s(:dot2, v1, v2).line v1.line
                      end
                    }
                | arg tDOT3 arg
                    {
                      v1, v2 = val[0], val[2]
                      if v1.node_type == :lit and v2.node_type == :lit and Integer === v1.last and Integer === v2.last then
                        result = s(:lit, (v1.last)...(v2.last)).line v1.line
                      else
                        result = s(:dot3, v1, v2).line v1.line
                      end
                    }
#if V >= 26
                | arg tDOT2
                    {
                      v1, _ = val
                      v2 = nil

                      result = s(:dot2, v1, v2).line v1.line
                    }
                | arg tDOT3
                    {
                      v1, _ = val
                      v2 = nil

                      result = s(:dot3, v1, v2).line v1.line
                    }
#endif

#if V >= 27
                | tBDOT2 arg
                    {
                      _, v2, = val
                      v1 = nil

                      result = s(:dot2, v1, v2).line v2.line
                    }
                | tBDOT3 arg
                    {
                      _, v2 = val
                      v1 = nil

                      result = s(:dot3, v1, v2).line v2.line
                    }
#endif

                | arg tPLUS arg
                    {
                      result = new_call val[0], :+, argl(val[2])
                    }
                | arg tMINUS arg
                    {
                      result = new_call val[0], :-, argl(val[2])
                    }
                | arg tSTAR2 arg # TODO: rename
                    {
                      result = new_call val[0], :*, argl(val[2])
                    }
                | arg tDIVIDE arg
                    {
                      result = new_call val[0], :"/", argl(val[2])
                    }
                | arg tPERCENT arg
                    {
                      result = new_call val[0], :"%", argl(val[2])
                    }
                | arg tPOW arg
                    {
                      result = new_call val[0], :**, argl(val[2])
                    }
#if V == 20
                | tUMINUS_NUM tINTEGER tPOW arg
                    {
                      lit = s(:lit, val[1]).line lexer.lineno
                      result = new_call(new_call(lit, :"**", argl(val[3])), :"-@")
                    }
                | tUMINUS_NUM tFLOAT tPOW arg
#else
                | tUMINUS_NUM simple_numeric tPOW arg
#endif
                    {
                      lit = s(:lit, val[1]).line lexer.lineno
                      result = new_call(new_call(lit, :"**", argl(val[3])), :"-@")

#if V == 20
                      ## TODO: why is this 2.0 only?
                      debug20 12, val, result
#endif
                    }
                | tUPLUS arg
                    {
                      result = new_call val[1], :"+@"
                    }
                | tUMINUS arg
                    {
                      result = new_call val[1], :"-@"
                    }
                | arg tPIPE arg
                    {
                      result = new_call val[0], :"|", argl(val[2])
                    }
                | arg tCARET arg
                    {
                      result = new_call val[0], :"^", argl(val[2])
                    }
                | arg tAMPER2 arg
                    {
                      result = new_call val[0], :"&", argl(val[2])
                    }
                | arg tCMP arg
                    {
                      result = new_call val[0], :"<=>", argl(val[2])
                    }
                | rel_expr                      =tCMP
                | arg tEQ arg
                    {
                      result = new_call val[0], :"==", argl(val[2])
                    }
                | arg tEQQ arg
                    {
                      result = new_call val[0], :"===", argl(val[2])
                    }
                | arg tNEQ arg
                    {
                      result = new_call val[0], :"!=", argl(val[2])
                    }
                | arg tMATCH arg
                    {
                      lhs, _, rhs = val
                      result = new_match lhs, rhs
                    }
                | arg tNMATCH arg
                    {
                      lhs, _, rhs = val
                      result = s(:not, new_match(lhs, rhs)).line lhs.line
                    }
                | tBANG arg
                    {
                      _, arg = val
                      result = new_call arg, :"!"
                      result.line arg.line
                    }
                | tTILDE arg
                    {
                      result = new_call value_expr(val[1]), :"~"
                    }
                | arg tLSHFT arg
                    {
                      val[0] = value_expr val[0]
                      val[2] = value_expr val[2]
                      result = new_call val[0], :"\<\<", argl(val[2])
                    }
                | arg tRSHFT arg
                    {
                      val[0] = value_expr val[0]
                      val[2] = value_expr val[2]
                      result = new_call val[0], :">>", argl(val[2])
                    }
                | arg tANDOP arg
                    {
                      result = logical_op :and, val[0], val[2]
                    }
                | arg tOROP arg
                    {
                      result = logical_op :or, val[0], val[2]
                    }
                | kDEFINED opt_nl arg
                    {
                      (_, line), _, arg = val
                      result = s(:defined, arg).line line
                    }
                | arg tEH arg opt_nl tCOLON arg
                    {
                      c, _, t, _, _, f = val
                      result = s(:if, c, t, f).line c.line
                    }
                | primary

           relop: tGT
                | tLT
                | tGEQ
                | tLEQ

        rel_expr: arg      relop arg                    =tGT
                    {
                      lhs, op, rhs = val
                      result = new_call lhs, op.to_sym, argl(rhs)
                    }
                | rel_expr relop arg                    =tGT
                    {
                      lhs, op, rhs = val
                      warn "comparison '%s' after comparison", op
                      result = new_call lhs, op.to_sym, argl(rhs)
                    }

       arg_value: arg
                    {
                      result = value_expr(val[0])
                    }

       aref_args: none
                | args trailer
                    {
                      result = args [val[0]]
                    }
                | args tCOMMA assocs trailer
                    {
                      result = args [val[0], array_to_hash(val[2])]
                    }
                | assocs trailer
                    {
                      result = args [array_to_hash(val[0])]
                    }

         arg_rhs: arg                   =tOP_ASGN
                | arg kRESCUE_MOD arg
                    {
                      body, (_, line), resbody = val
                      body    = value_expr body
                      resbody = remove_begin resbody

                      ary = s(:array).line line
                      result  = new_rescue(body, new_resbody(ary, resbody))
                    }

      paren_args: tLPAREN2 opt_call_args rparen
                    {
                      _, args, _ = val
                      result = args
                    }
#if V >= 27
                | tLPAREN2 args tCOMMA args_forward rparen
                    {
                      yyerror "Unexpected ..." unless
                        self.lexer.is_local_id(:"*")  &&
                        self.lexer.is_local_id(:"**") &&
                        self.lexer.is_local_id(:"&")

                      result = call_args val
                    }
                | tLPAREN2 args_forward rparen
                    {
                      yyerror "Unexpected ..." unless
                        self.lexer.is_local_id(:"*")  &&
                        self.lexer.is_local_id(:"**") &&
                        self.lexer.is_local_id(:"&")

                      result = call_args val
                    }
#endif

  opt_paren_args: none
                | paren_args

   opt_call_args: none
                | call_args
                | args tCOMMA
                    {
                      result = args val
                    }
                | args tCOMMA assocs tCOMMA
                    {
                      result = args [val[0], array_to_hash(val[2])]
                    }
                | assocs tCOMMA
                    {
                      result = args [array_to_hash(val[0])]
                    }

       call_args: command
                    {
                      warning "parenthesize argument(s) for future version"
                      result = call_args val
                    }
                | args opt_block_arg
                    {
                      result = call_args val
                    }
                | assocs opt_block_arg
                    {
                      result = call_args [array_to_hash(val[0]), val[1]]
                    }
                | args tCOMMA assocs opt_block_arg
                    {
                      result = call_args [val[0], array_to_hash(val[2]), val[3]]
                    }
                | block_arg
                    {
                      result = call_args val
                    }

    command_args:   {
                      # parse26.y line 2200

                      # If call_args starts with a open paren '(' or
                      # '[', look-ahead reading of the letters calls
                      # CMDARG_PUSH(0), but the push must be done
                      # after CMDARG_PUSH(1). So this code makes them
                      # consistent by first cancelling the premature
                      # CMDARG_PUSH(0), doing CMDARG_PUSH(1), and
                      # finally redoing CMDARG_PUSH(0).

                      result = yychar = self.last_token_type.first
                      lookahead = [:tLPAREN, :tLPAREN_ARG, :tLPAREN2, :tLBRACK, :tLBRACK2].include?(yychar)
                      lexer.cmdarg.pop if lookahead
                      lexer.cmdarg.push true
                      lexer.cmdarg.push false if lookahead
                    }
                      call_args
                    {
                      yychar, args = val

                      # call_args can be followed by tLBRACE_ARG (that
                      # does CMDARG_PUSH(0) in the lexer) but the push
                      # must be done after CMDARG_POP() in the parser.
                      # So this code does CMDARG_POP() to pop 0 pushed
                      # by tLBRACE_ARG, CMDARG_POP() to pop 1 pushed
                      # by command_args, and CMDARG_PUSH(0) to restore
                      # back the flag set by tLBRACE_ARG.

                      lookahead = [:tLBRACE_ARG].include?(yychar)
                      lexer.cmdarg.pop if lookahead
                      lexer.cmdarg.pop
                      lexer.cmdarg.push false if lookahead
                      result = args
                    }

       block_arg: tAMPER arg_value
                    {
                      _, arg = val
                      result = s(:block_pass, arg).line arg.line
                    }

   opt_block_arg: tCOMMA block_arg
                    {
                      result = val[1]
                    }
                | none

            args: arg_value
                    {
                      arg, = val
                      lineno = arg.line || lexer.lineno # HACK

                      result = s(:array, arg).line lineno
                    }
                | tSTAR arg_value
                    {
                      _, arg = val
                      result = s(:array, s(:splat, arg).line(arg.line)).line arg.line
                    }
                | args tCOMMA arg_value
                    {
                      args, _, id = val
                      result = self.list_append args, id
                    }
                | args tCOMMA tSTAR arg_value
                    {
                      # TODO: the line number from tSTAR has been dropped
                      args, _, _, id = val
                      line = lexer.lineno
                      result = self.list_append args, s(:splat, id).line(line)
                    }

#if V >= 21
        mrhs_arg: mrhs
                    {
                      result = new_masgn_arg val[0]
                    }
                | arg_value
                    {
                      result = new_masgn_arg val[0], :wrap
                    }

#endif
            mrhs: args tCOMMA arg_value
                    {
                      result = val[0] << val[2]
                    }
                | args tCOMMA tSTAR arg_value
                    {
                      # TODO: make all tXXXX terminals include lexer.lineno
                      arg, _, _, splat = val
                      result = self.arg_concat arg, splat
                    }
                | tSTAR arg_value
                    {
                      _, arg = val
                      result = s(:splat, arg).line arg.line
                    }

         primary: literal
                | strings
                | xstring
                | regexp
                | words
                | qwords
                | symbols
                | qsymbols
                | var_ref
                | backref
                | tFID
                    {
                      msg, = val
                      result = new_call nil, msg.to_sym
                    }
                | k_begin
                    {
                      lexer.cmdarg.push false
                      result = self.lexer.lineno
                    }
                    bodystmt k_end
                    {
                      lexer.cmdarg.pop
                      result = new_begin val
                    }
                | tLPAREN_ARG
                    {
                      lexer.lex_state = EXPR_ENDARG
                      result = lexer.lineno
                    }
                    rparen
                    {
                      _, line, _ = val
                      result = s(:begin).line line
                    }
                | tLPAREN_ARG
                    stmt
                    {
                      lexer.lex_state = EXPR_ENDARG
                    }
                    rparen
                    {
                      _, stmt, _, _, = val
                      # warning "(...) interpreted as grouped expression"
                      result = stmt
                    }
                | tLPAREN compstmt tRPAREN
                    {
                      _, stmt, _ = val
                      result = stmt
                      result ||= s(:nil).line lexer.lineno
                      result.paren = true
                    }
                | primary_value tCOLON2 tCONSTANT
                    {
                      expr, _, id = val

                      result = s(:colon2, expr, id.to_sym).line expr.line
                    }
                | tCOLON3 tCONSTANT
                    {
                      _, id = val

                      result = s(:colon3, id.to_sym).line lexer.lineno
                    }
                | tLBRACK { result = lexer.lineno } aref_args tRBRACK
                    {
                      _, line, args, _ = val
                      result = args || s(:array)
                      result.sexp_type = :array # aref_args is :args
                      result.line line
                    }
                | tLBRACE
                    {
                      result = self.lexer.lineno
                    }
                    assoc_list tRCURLY
                    {
                      result = new_hash val
                    }
                | k_return
                    {
                      (_, line), = val
                      result = s(:return).line line
                    }
                | kYIELD tLPAREN2 call_args rparen
                    {
                      result = new_yield val[2]
                    }
                | kYIELD tLPAREN2 rparen
                    {
                      result = new_yield
                    }
                | kYIELD
                    {
                      result = new_yield
                    }
                | kDEFINED opt_nl tLPAREN2 expr rparen
                    {
                      (_, line), _, _, arg, _ = val

                      result = s(:defined, arg).line line
                    }
                | kNOT tLPAREN2 expr rparen
                    {
                      _, _, lhs, _ = val
                      result = new_call lhs, :"!"
                    }
                | kNOT tLPAREN2 rparen
                    {
                      debug20 14, val, result
                    }
                | fcall brace_block
                    {
                      call, iter = val

                      iter.insert 1, call
                      result = iter
                      # FIX: probably not: call.line = iter.line
                    }
                | method_call
                | method_call brace_block
                    {
                      call, iter = val[0], val[1]
                      block_dup_check call, iter
                      iter.insert 1, call # FIX
                      result = iter
                    }
                | tLAMBDA lambda
                    {
                      result = val[1] # TODO: fix lineno
                    }
                | k_if expr_value then compstmt if_tail k_end
                    {
                      _, c, _, t, f, _ = val
                      result = new_if c, t, f
                    }
                | k_unless expr_value then compstmt opt_else k_end
                    {
                      _, c, _, t, f, _ = val
                      result = new_if c, f, t
                    }
                | k_while expr_value_do compstmt k_end
                    {
                      _, cond, body, _ = val
                      result = new_while body, cond, true
                    }
                | k_until expr_value_do compstmt k_end
                    {
                      _, cond, body, _ = val
                      result = new_until body, cond, true
                    }
                | k_case expr_value opt_terms case_body k_end
                    {
                      (_, line), expr, _, body, _ = val
                      result = new_case expr, body, line
                    }
                | k_case            opt_terms case_body k_end
                    {
                      (_, line), _, body, _ = val
                      result = new_case nil, body, line
                    }
#if V >= 27
                | k_case expr_value opt_terms p_case_body k_end
                    {
                      (_, line), expr, _, body, _ = val

                      result = new_case expr, body, line
                    }
#endif
                | k_for for_var kIN expr_value_do compstmt k_end
                    {
                      _, var, _, iter, body, _ = val
                      result = new_for iter, var, body
                    }
                | k_class
                    {
                      result = self.lexer.lineno
                    }
                    cpath superclass
                    {
                      if (self.in_def || self.in_single > 0) then
                        yyerror "class definition in method body"
                      end
                      self.env.extend
                    }
                    bodystmt k_end
                    {
                      result = new_class val
                      self.env.unextend
                      self.lexer.ignore_body_comments
                    }
                | k_class tLSHFT
                    {
                      result = self.lexer.lineno
                    }
                    expr
                    {
                      result = self.in_def
                      self.in_def = false
                    }
                    term
                    {
                      result = self.in_single
                      self.in_single = 0
                      self.env.extend
                    }
                    bodystmt k_end
                    {
                      result = new_sclass val
                      self.env.unextend
                      self.lexer.ignore_body_comments
                    }
                | k_module
                    {
                      result = self.lexer.lineno
                    }
                    cpath
                    {
                      yyerror "module definition in method body" if
                        self.in_def or self.in_single > 0

                      self.env.extend
                    }
                    bodystmt k_end
                    {
                      result = new_module val
                      self.env.unextend
                      self.lexer.ignore_body_comments
                    }
                | k_def fname
                    {
                      result = self.in_def

                      self.in_def = true # group = local_push
                      self.env.extend
                      lexer.cmdarg.push false
                      lexer.cond.push false
                    }
                    f_arglist bodystmt { result = lexer.lineno } k_end
                    {
                      in_def = val[2]

                      result = new_defn val

                      lexer.cond.pop # group = local_pop
                      lexer.cmdarg.pop
                      self.env.unextend
                      self.in_def = in_def

                      self.lexer.ignore_body_comments
                    }
                | k_def singleton dot_or_colon
                    {
                      lexer.lex_state = EXPR_FNAME
                    }
                    fname
                    {
                      result = [self.in_def, lexer.lineno]

                      self.in_single += 1 # TODO: remove?

                      self.in_def = true # local_push
                      self.env.extend
                      lexer.cmdarg.push false
                      lexer.cond.push false

                      lexer.lex_state = EXPR_ENDFN|EXPR_LABEL
                    }
                    f_arglist bodystmt k_end
                    {
                      _, _recv, _, _, _name, (in_def, _lineno), _args, _body, _ = val

                      result = new_defs val

                      lexer.cond.pop # group = local_pop
                      lexer.cmdarg.pop
                      self.env.unextend
                      self.in_def = in_def

                      self.in_single -= 1

                      # TODO: restore cur_arg ? what's cur_arg?

                      self.lexer.ignore_body_comments
                    }
                | kBREAK
                    {
                      (_, line), = val
                      result = s(:break).line line
                    }
                | kNEXT
                    {
                      (_, line), = val
                      result = s(:next).line line
                    }
                | kREDO
                    {
                      (_, line), = val
                      result = s(:redo).line line
                    }
                | kRETRY
                    {
                      (_, line), = val
                      result = s(:retry).line line
                    }

   primary_value: primary
                    {
                      result = value_expr(val[0])
                    }

                    # These are really stupid
         k_begin: kBEGIN
            k_if: kIF
        k_unless: kUNLESS
         k_while: kWHILE
         k_until: kUNTIL
          k_case: kCASE
           k_for: kFOR
         k_class: kCLASS
                    {
                      self.comments.push self.lexer.comments
                    }
        k_module: kMODULE
                    {
                      self.comments.push self.lexer.comments
                    }
           k_def: kDEF
                    {
                      self.comments.push self.lexer.comments
                    }
            k_do: kDO
      k_do_block: kDO_BLOCK
        k_rescue: kRESCUE
        k_ensure: kENSURE
          k_when: kWHEN
          k_else: kELSE
         k_elsif: kELSIF
           k_end: kEND
        k_return: kRETURN

            then: term
                | kTHEN
                | term kTHEN

              do: term
                | kDO_COND

         if_tail: opt_else
                | k_elsif expr_value then compstmt if_tail
                    {
                      (_, line), c, _, t, rest = val

                      result = s(:if, c, t, rest).line line
                    }

        opt_else: none
                | kELSE compstmt
                    {
                      result = val[1]
                    }

         for_var: lhs
                | mlhs
                    {
                      val[0].delete_at 1 if val[0][1].nil? # HACK
                    }

          f_marg: f_norm_arg
                | tLPAREN f_margs rparen
                    {
                      result = val[1]
                    }

     f_marg_list: f_marg
                    {
                      sym, = val

                      result = s(:array, sym).line lexer.lineno
                    }
                | f_marg_list tCOMMA f_marg
                    {
                      result = list_append val[0], val[2]
                    }

         f_margs: f_marg_list
                    {
                      args, = val

                      result = block_var args
                    }
                | f_marg_list tCOMMA f_rest_marg
                    {
                      args, _, rest = val

                      result = block_var args, rest
                    }
                | f_marg_list tCOMMA f_rest_marg tCOMMA f_marg_list
                    {
                      lhs, _, splat, _, rhs = val

                      result = block_var lhs, splat, rhs
                    }
                | f_rest_marg
                    {
                      rest, = val

                      result = block_var rest
                    }
                | f_rest_marg tCOMMA f_marg_list
                    {
                      splat, _, rest = val

                      result = block_var splat, rest
                    }

     f_rest_marg: tSTAR f_norm_arg
                    {
                      _, splat = val

                      result = args [:"*#{splat}"]
                    }
                | tSTAR
                    {
                      result = args [:*]
                    }

 block_args_tail: f_block_kwarg tCOMMA f_kwrest opt_f_block_arg
                    {
                      result = call_args val
                    }
                | f_block_kwarg opt_f_block_arg
                    {
                      result = call_args val
                    }
                | f_kwrest opt_f_block_arg
                    {
                      result = call_args val
                    }
#if V >= 27
                | f_no_kwarg opt_f_block_arg
                    {
                      result = args val
                    }
#endif
                | f_block_arg
                    {
                      line = lexer.lineno
                      result = call_args val # TODO: push line down
                      result.line line
                    }

opt_block_args_tail: tCOMMA block_args_tail
                    {
                      result = args val
                    }
                | none

     block_param: f_arg tCOMMA f_block_optarg tCOMMA f_rest_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_block_optarg tCOMMA f_rest_arg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_block_optarg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_block_optarg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_rest_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA
                    {
                      result = args(val) << nil
                    }
                | f_arg tCOMMA f_rest_arg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_block_optarg tCOMMA f_rest_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_block_optarg tCOMMA f_rest_arg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_block_optarg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_block_optarg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_rest_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | f_rest_arg tCOMMA f_arg opt_block_args_tail
                    {
                      result = args val
                    }
                | block_args_tail
                    {
                      result = args val
                    }

 opt_block_param: none { result = 0 }
                | block_param_def
                    {
                      self.lexer.command_start = true
                    }

 block_param_def: tPIPE opt_bv_decl tPIPE
                    {
                      # TODO: current_arg = 0
                      result = args val
                    }
                | tOROP
                    {
                      result = s(:args).line lexer.lineno
                    }
                | tPIPE block_param opt_bv_decl tPIPE
                    {
                      # TODO: current_arg = 0
                      result = args val
                    }

     opt_bv_decl: opt_nl
                | opt_nl tSEMI bv_decls opt_nl
                    {
                      result = args val
                    }

        bv_decls: bvar
                    {
                      result = args val
                    }
                | bv_decls tCOMMA bvar
                    {
                      result = args val
                    }

            bvar: tIDENTIFIER
                    {
                      id, = val
                      line = lexer.lineno
                      result = s(:shadow, id.to_sym).line line
                    }
                | f_bad_arg

          lambda:   {
                      self.env.extend :dynamic
                      result = [lexer.lineno, lexer.lpar_beg]
                      lexer.paren_nest += 1
                      lexer.lpar_beg = lexer.paren_nest
                    }
                    f_larglist
                    {
                      lexer.cmdarg.push false
                    }
                    lambda_body
                    {
                      (line, lpar), args, _cmdarg, body = val
                      lexer.lpar_beg = lpar

                      lexer.cmdarg.pop

                      call = s(:lambda).line line
                      result = new_iter call, args, body
                      result.line = line
                      self.env.unextend # TODO: dynapush & dynapop
                    }

     f_larglist: tLPAREN2 f_args opt_bv_decl rparen
                    {
                      result = args val
                    }
                | f_args
                    {
                      result = val[0]
                      result = 0 if result == s(:args)
                    }

     lambda_body: tLAMBEG compstmt tRCURLY
                    {
                      result = val[1]
                    }
                | kDO_LAMBDA bodystmt kEND
                    {
                      result = val[1]
                    }

        do_block: k_do_block do_body kEND
                    {
                      (_, line), iter, _ = val
                      result = iter.line line
                    }

      block_call: command do_block
                    {
                      # TODO:
                      ## if (nd_type($1) == NODE_YIELD) {
                      ##     compile_error(PARSER_ARG "block given to yield");

                      syntax_error "Both block arg and actual block given." if
                        val[0].block_pass?

                      val = invert_block_call val if inverted? val

                      cmd, blk = val

                      result = blk
                      result.insert 1, cmd
                    }
                | block_call call_op2 operation2 opt_paren_args
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | block_call call_op2 operation2 opt_paren_args brace_block
                    {
                      iter1, _, name, args, iter2 = val

                      call = new_call iter1, name.to_sym, args
                      iter2.insert 1, call

                      result = iter2
                    }
                | block_call call_op2 operation2 command_args do_block
                    {
                      iter1, _, name, args, iter2 = val

                      call = new_call iter1, name.to_sym, args
                      iter2.insert 1, call

                      result = iter2
                    }

     method_call: fcall
                    {
                      result = self.lexer.lineno
                    }
                    paren_args
                    {
                      call, lineno, args = val

                      result = call.concat args.sexp_body if args
                      result.line lineno
                    }
                | primary_value call_op operation2 opt_paren_args
                    {
                      result = new_call val[0], val[2].to_sym, val[3], val[1]
                    }
                | primary_value tCOLON2 operation2 paren_args
                    {
                      result = new_call val[0], val[2].to_sym, val[3]
                    }
                | primary_value tCOLON2 operation3
                    {
                      result = new_call val[0], val[2].to_sym
                    }
                | primary_value call_op paren_args
                    {
                      result = new_call val[0], :call, val[2], val[1]
                    }
                | primary_value tCOLON2 paren_args
                    {
                      result = new_call val[0], :call, val[2]
                    }
                | kSUPER paren_args
                    {
                      result = new_super val[1]
                    }
                | kSUPER
                    {
                      result = s(:zsuper).line lexer.lineno
                    }
                | primary_value tLBRACK2 opt_call_args rbracket
                    {
                      result = new_aref val
                    }

     brace_block: tLCURLY
                    {
                      self.env.extend :dynamic
                      result = self.lexer.lineno
                    }
                    brace_body tRCURLY
                    {
                      _, line, body, _ = val

                      result = body
                      result.line = line

                      self.env.unextend
                    }
                | k_do
                    {
                      self.env.extend :dynamic
                      result = self.lexer.lineno
                    }
                    do_body kEND
                    {
                      _, line, body, _ = val

                      result = body
                      result.line = line

                      self.env.unextend
                    }

      brace_body:   { self.env.extend :dynamic; result = self.lexer.lineno }
                    { result = lexer.cmdarg.store(false) }
                    opt_block_param compstmt
                    {
                      line, cmdarg, param, cmpstmt = val

                      result = new_brace_body param, cmpstmt, line
                      self.env.unextend
                      lexer.cmdarg.restore cmdarg
                      lexer.cmdarg.pop # because of: cmdarg_stack >> 1 ?
                    }

         do_body:   { self.env.extend :dynamic; result = self.lexer.lineno }
                    { lexer.cmdarg.push false }
                    opt_block_param
#if V >= 25
                    bodystmt
#else
                    compstmt
#endif
                    {
                      line, _cmdarg, param, cmpstmt = val

                      result = new_do_body param, cmpstmt, line
                      lexer.cmdarg.pop
                      self.env.unextend
                    }

       case_args: arg_value
                    {
                      arg, = val

                      result = s(:array, arg).line arg.line
                    }
                | tSTAR arg_value
                    {
                      _, arg = val

                      result = s(:array, s(:splat, arg).line(arg.line)).line arg.line
                    }
                | case_args tCOMMA arg_value
                    {
                      args, _, id = val

                      result = self.list_append args, id
                    }
                | case_args tCOMMA tSTAR arg_value
                    {
                      args, _, _, id = val

                      result = self.list_append args, s(:splat, id).line(id.line)
                    }

       case_body: k_when
                    {
                      result = self.lexer.lineno
                    }
                    case_args then compstmt cases
                    {
                      result = new_when(val[2], val[4])
                      result.line = val[1]
                      result << val[5] if val[5]
                    }

           cases: opt_else | case_body
#if V >= 27
######################################################################

     p_case_body: kIN
                    {
                      self.lexer.lex_state = EXPR_BEG|EXPR_LABEL
                      self.lexer.command_start = false
                      result = self.in_kwarg
                      self.in_kwarg = true
                      self.env.extend
                      # TODO? {$<tbl>$ = push_pktbl(p);}
                    }
                    p_top_expr
                    then
                    {
                      # TODO? {pop_pktbl(p, $<tbl>4);}
                      old_kwargs = _values[-3]
                      self.in_kwarg = old_kwargs
                      self.env.unextend
                    }
                    compstmt
                    p_cases
                    {
                      (_, line), _, pat, _, _, body, cases = val

                      result = new_in pat, body, cases, line
                    }

         p_cases: opt_else
                | p_case_body

      p_top_expr: p_top_expr_body
                | p_top_expr_body kIF_MOD expr_value
                    {
                      body, _, cond = val
                      body = remove_begin body

                      result = s(:if, cond, body, nil).line body.line
                    }
                | p_top_expr_body kUNLESS_MOD expr_value
                    {
                      body, _, cond = val
                      body = remove_begin body

                      result = s(:if, cond, nil, body).line body.line
                    }

 p_top_expr_body: p_expr
                | p_expr tCOMMA
                    {
                      expr, _ = val

                      tail = new_array_pattern_tail nil, true, nil, nil
                      result = new_array_pattern nil, expr, tail, expr.line
                    }
                | p_expr tCOMMA p_args
                    {
                      expr, _, args = val

                      result = new_array_pattern nil, expr, args, expr.line
                    }
                | p_args_tail
                    {
                      args, = val
                      result = new_array_pattern nil, nil, args, args.line
                    }
                | p_kwargs
                    {
                      kwargs, = val
                      result = new_hash_pattern nil, kwargs, kwargs.line
                    }

          p_expr: p_as

            p_as: p_expr tASSOC p_variable
                    {
                      # NODE *n = NEW_LIST($1, &@$);
                      # n = list_append(p, n, $3);
                      # $$ = new_hash(p, n, &@$);

                      expr, _, var = val

                      id = var.last

                      self.env[id] = :lvar # HACK: need to extend env
                      lhs = s(:lasgn, id).line var.line

                      result = new_assign lhs, expr
                    }
                | p_alt

           p_alt: p_alt tPIPE p_expr_basic
                    {
                      lhs, _, rhs = val

                      result = s(:or, lhs, rhs)
                    }
                | p_expr_basic

        p_lparen: tLPAREN2 # TODO: {$<tbl>$ = push_pktbl(p);};

      p_lbracket: tLBRACK2 # TODO: {$<tbl>$ = push_pktbl(p);};

    p_expr_basic: p_value
                | p_const p_lparen p_args tRPAREN
                    {
                      lhs, _, args, _ = val

                      # TODO: pop_pktbl(p, $<tbl>2);
                      result = new_array_pattern(lhs, nil, args, lhs.line)
                    }
                | p_const p_lparen p_kwargs tRPAREN
                    {
                      lhs, _, kwargs, _ = val

                      # TODO: pop_pktbl(p, $<tbl>2);
                      result = new_hash_pattern(lhs, kwargs, lhs.line)
                    }
                | p_const tLPAREN2 tRPAREN { not_yet 23 }
                | p_const p_lbracket p_args rbracket
                    {
                      const, _, pre_arg, _ = val
                      # TODO: pop_pktbl(p, $<tbl>2);
                      result = new_array_pattern const, nil, pre_arg, const.line
                    }
                | p_const p_lbracket p_kwargs rbracket { not_yet 25 }
                | p_const tLBRACK rbracket { not_yet 26 }
                | tLBRACK
                    {
                      # TODO: $$ = push_pktbl(p);
                      result = true
                    }
                    p_args rbracket
                    {
                      # TODO: pop_pktbl(p, $<tbl>2); ?
                      _, _, pat, _ = val

                      result = new_array_pattern nil, nil, pat, pat.line
                    }
                | tLBRACK rbracket
                    {
                      _, _ = val

                      result = s(:array_pat).line lexer.lineno
                    }
                | tLBRACE
                    {
                      # TODO: $<tbl>$ = push_pktbl(p)
                      result = self.in_kwarg
                      self.in_kwarg = false
                    }
                    p_kwargs rbrace
                    {
                      _, in_kwarg, kwargs, _ = val

                      # TODO: pop_pktbl(p, $<tbl>2)
                      self.in_kwarg = in_kwarg

                      result = new_hash_pattern(nil, kwargs, kwargs.line)
                    }
                | tLBRACE rbrace { not_yet 30 }
                | tLPAREN p_expr tRPAREN { not_yet 31 }

          p_args: p_expr
                    {
                      expr, = val

                      ary = s(:array_TAIL, expr).line expr.line
                      result = new_array_pattern_tail(ary, nil, nil, nil).line expr.line
                    }
                | p_args_head { not_yet 33 }
                | p_args_head p_arg
                    {
                      head, tail = val

                      both = array_pat_concat head, tail

                      result = new_array_pattern_tail both, nil, nil, nil
                      result.line head.line
                    }
                | p_args_head tSTAR tIDENTIFIER
                    {
                      head, _, id = val

                      result = new_array_pattern_tail head, true, id.to_sym, nil
                      result.line head.line
                    }
                | p_args_head tSTAR tIDENTIFIER tCOMMA p_args_post { not_yet 36 }
                | p_args_head tSTAR
                    {
                      expr, _ = val

                      result = new_array_pattern_tail(expr, true, nil, nil).line expr.line
                    }
                | p_args_head tSTAR tCOMMA p_args_post { not_yet 38 }
                | p_args_tail

     p_args_head: p_arg tCOMMA
                    {
                      arg, _ = val
                      result = arg
                    }
                | p_args_head p_arg tCOMMA
                    {
                      head, tail, _ = val

                      result = s(:PATTERN, *head.sexp_body, *tail.sexp_body)
                      result.line head.line
                    }

     p_args_tail: tSTAR tIDENTIFIER
                    {
                      _, id = val

                      result = new_array_pattern_tail nil, true, id.to_sym, nil
                      result.line lexer.lineno
                    }
                | tSTAR tIDENTIFIER tCOMMA p_args_post { not_yet 43 }
                | tSTAR
                    {
                      result = new_array_pattern_tail nil, true, nil, nil
                      result.line lexer.lineno
                    }
                | tSTAR tCOMMA p_args_post
                    {
                      _, _, args = val

                      result = new_array_pattern_tail nil, true, nil, args
                      result.line args.line
                    }

     p_args_post: p_arg
                | p_args_post tCOMMA p_arg
                    {
                      lhs, _, rhs = val

                      result = array_pat_concat lhs, rhs
                    }

           p_arg: p_expr
                    {
                      expr, = val
                      expr = s(:array_TAIL, expr).line expr.line unless
                        expr.sexp_type == :array_TAIL
                      result = expr
                    }

        p_kwargs: p_kwarg tCOMMA p_kwrest
                    {
                      kw_arg, _, rest = val
                      # xxx = new_unique_key_hash(p, $1, &@$)
                      result = new_hash_pattern_tail kw_arg, rest, kw_arg.line
                    }
                | p_kwarg
                    {
                      kwarg, = val
                      # TODO? new_unique_key_hash(p, $1, &@$)
                      result = new_hash_pattern_tail kwarg, nil, kwarg.line
                    }
                | p_kwarg tCOMMA
                    {
                      kwarg, _ = val
                      # TODO? new_unique_key_hash(p, $1, &@$)
                      result = new_hash_pattern_tail kwarg, nil, kwarg.line
                    }
                | p_kwrest
                    {
                      rest, = val

                      # HACK: fix lineno
                      result = new_hash_pattern_tail nil, rest, self.lexer.lineno

                    }
                | p_kwarg tCOMMA p_kwnorest { not_yet 53 }
                | p_kwnorest { not_yet 54 }

         p_kwarg: p_kw # TODO? rb_ary_new_from_args(1, $1)
                | p_kwarg tCOMMA p_kw
                    {
                      kwarg, _, kw = val
                      kwarg.concat kw.sexp_body
                      result = kwarg
                    }

            p_kw: p_kw_label p_expr
                    {
                      # TODO: error_duplicate_pattern_key(p, get_id($1), &@1);
                      lhs, rhs = val

                      result = s(:PAIR, lhs, rhs).line lhs.line
                    }
                | p_kw_label
                    {
                      lhs, = val

                      result = s(:PAIR, lhs, nil).line lhs.line
                    }

      p_kw_label: tLABEL
                    {
                      (id, line), = val

                      result = s(:lit, id.to_sym).line line
                    }
                | tSTRING_BEG string_contents tLABEL_END { not_yet 60 }

        p_kwrest: kwrest_mark tIDENTIFIER
                    {
                      _, id = val

                      name = id.to_sym
                      self.assignable name
                      result = :"**#{name}"
                    }
                | kwrest_mark
                    {
                      result = :"**"
                    }

      p_kwnorest: kwrest_mark kNIL { not_yet 63 }

         p_value: p_primitive
                | p_primitive tDOT2 p_primitive { not_yet 65 }
                | p_primitive tDOT3 p_primitive { not_yet 66 }
                | p_primitive tDOT2
                    {
                      v1, _ = val
                      result = s(:dot2, v1, nil).line v1.line
                    }
                | p_primitive tDOT3 { not_yet 68 }
                | p_variable
                | p_var_ref
                | p_const
                | tBDOT2 p_primitive { not_yet 72 }
                | tBDOT3 p_primitive { not_yet 73 }

     p_primitive: literal
                | strings
                | xstring { not_yet 76 }
                | regexp
                | words { not_yet 78 }
                | qwords { not_yet 79 }
                | symbols { not_yet 80 }
                | qsymbols { not_yet 81 }
                | keyword_variable
                    {
                      # TODO? if (!($$ = gettable(p, $1, &@$))) $$ = NEW_BEGIN(0, &@$);
                      var, = val

                      result = var
                    }
                | tLAMBDA lambda { not_yet 83 }

      p_variable: tIDENTIFIER
                    {
                      id, = val

                      # TODO: error_duplicate_pattern_variable(p, $1, &@1);
                      # TODO: assignable(p, $1, 0, &@$);
                      result = s(:lvar, id.to_sym).line lexer.lineno
                    }

       p_var_ref: tCARET tIDENTIFIER
                    {
                      _, id = val

                      # TODO: check id against env for lvar or dvar

                      result = s(:lvar, id.to_sym).line lexer.lineno
                    }

         p_const: tCOLON3 cname
                    {
                      _, id = val
                      result = s(:colon3, id.to_sym).line lexer.lineno
                    }
                | p_const tCOLON2 cname
                    {
                      lhs, _, name = val

                      l = lhs.line
                      result = s(:const, s(:colon2, lhs, name.to_sym).line(l)).line l
                    }
                | tCONSTANT
                    {
                      # TODO $$ = gettable(p, $1, &@$);

                      name, = val
                      result = s(:const, name.to_sym).line self.lexer.lineno
                    }
######################################################################
#endif

      opt_rescue: k_rescue exc_list exc_var then compstmt opt_rescue
                    {
                      (_, line), klasses, var, _, body, rest = val

                      klasses ||= s(:array)
                      klasses << new_assign(var, s(:gvar, :"$!").line(var.line)) if var
                      klasses.line line

                      result = new_resbody(klasses, body)
                      result << rest if rest # UGH, rewritten above
                    }
                |
                    {
                      result = nil
                    }

        exc_list: arg_value
                    {
                      arg, = val
                      result = s(:array, arg).line arg.line
                    }
                | mrhs
                | none

         exc_var: tASSOC lhs
                    {
                      result = val[1]
                    }
                | none

      opt_ensure: k_ensure compstmt
                    {
                      (_, line), body = val

                      result = body || s(:nil).line(line)
                    }
                | none

         literal: numeric
                    {
                      line = lexer.lineno
                      result = s(:lit, val[0])
                      result.line = line
                    }
                | symbol

         strings: string
                    {
                      str, = val
                      str = s(:dstr, str.value) if str.sexp_type == :evstr
                      result = str
                    }

          string: tCHAR
                    {
                      debug20 23, val, result
                    }
                | string1
                | string string1
                    {
                      result = self.literal_concat val[0], val[1]
                    }

         string1: tSTRING_BEG string_contents tSTRING_END
                    {
                      _, str, (_, func) = val

                      str = dedent str if func =~ RubyLexer::STR_FUNC_ICNTNT

                      result = str
                    }
                | tSTRING
                    {
                      result = new_string val
                    }

         xstring: tXSTRING_BEG xstring_contents tSTRING_END
                    {
                      result = new_xstring val
                      # TODO: dedent?!?! SERIOUSLY?!?
                    }

          regexp: tREGEXP_BEG regexp_contents tREGEXP_END
                    {
                      result = new_regexp val
                    }

           words: tWORDS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array).line lexer.lineno
                    }
                | tWORDS_BEG word_list tSTRING_END
                    {
                      result = val[1]
                    }

       word_list: none
                    {
                      result = new_word_list
                    }
                | word_list word tSPACE
                    {
                      result = val[0].dup << new_word_list_entry(val)
                    }

            word: string_content
                | word string_content
                    {
                      result = self.literal_concat val[0], val[1]
                    }

         symbols: tSYMBOLS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array).line lexer.lineno
                    }
                | tSYMBOLS_BEG { result = lexer.lineno } symbol_list tSTRING_END
                    {
                      _, line, list, _, = val
                      list.line = line
                      result = list
                    }

     symbol_list: none
                    {
                      result = new_symbol_list.line lexer.lineno
                    }
                | symbol_list word tSPACE
                    {
                      list, * = val
                      result = list.dup << new_symbol_list_entry(val)
                    }

          qwords: tQWORDS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array).line lexer.lineno
                    }
                | tQWORDS_BEG qword_list tSTRING_END
                    {
                      result = val[1]
                    }

        qsymbols: tQSYMBOLS_BEG tSPACE tSTRING_END
                    {
                      result = s(:array).line lexer.lineno # FIX
                    }
                | tQSYMBOLS_BEG qsym_list tSTRING_END
                    {
                      result = val[1]
                    }

      qword_list: none
                    {
                      result = new_qword_list
                    }
                | qword_list tSTRING_CONTENT tSPACE
                    {
                      result = val[0].dup << new_qword_list_entry(val)
                    }

       qsym_list: none
                    {
                      result = new_qsym_list
                    }
                | qsym_list tSTRING_CONTENT tSPACE
                    {
                      result = val[0].dup << new_qsym_list_entry(val)
                    }

 string_contents: none
                    {
                      result = s(:str, "").line lexer.lineno
                    }
                | string_contents string_content
                    {
                      v1, v2 = val
                      result = literal_concat v1, v2
                    }

xstring_contents: none
                    {
                      result = nil
                    }
                | xstring_contents string_content
                    {
                      v1, v2 = val
                      result = literal_concat v1, v2
                    }

regexp_contents: none
                    {
                      result = nil
                    }
                | regexp_contents string_content
                    {
                      v1, v2 = val
                      result = literal_concat v1, v2
                    }

  string_content: tSTRING_CONTENT
                    {
                      result = new_string val
                    }
                | tSTRING_DVAR
                    {
                      result = lexer.lex_strterm

                      lexer.lex_strterm = nil
                      lexer.lex_state = EXPR_BEG
                    }
                    string_dvar
                    {
                      _, strterm, str = val
                      lexer.lex_strterm = strterm
                      result = s(:evstr, str).line str.line
                    }
                | tSTRING_DBEG
                    {
                      result = [lexer.lex_strterm,
                                lexer.brace_nest,
                                lexer.string_nest, # TODO: remove
                                lexer.lex_state,
                                lexer.lineno,
                               ]

                      lexer.cmdarg.push false
                      lexer.cond.push false

                      lexer.lex_strterm = nil
                      lexer.brace_nest  = 0
                      lexer.string_nest = 0

                      lexer.lex_state   = EXPR_BEG
                    }
                    compstmt
                    tSTRING_DEND
                    {
                      _, memo, stmt, _ = val

                      lex_strterm, brace_nest, string_nest, oldlex_state, line = memo
                      # TODO: heredoc_indent

                      lexer.lex_strterm = lex_strterm
                      lexer.brace_nest  = brace_nest
                      lexer.string_nest = string_nest

                      lexer.cmdarg.pop
                      lexer.cond.pop

                      lexer.lex_state = oldlex_state

                      case stmt
                      when Sexp then
                        case stmt.sexp_type
                        when :str, :dstr, :evstr then
                          result = stmt
                        else
                          result = s(:evstr, stmt).line line
                        end
                      when nil then
                        result = s(:evstr).line line
                      else
                        debug20 25
                        raise "unknown string body: #{stmt.inspect}"
                      end
                    }

     string_dvar: tGVAR { result = s(:gvar, val[0].to_sym).line lexer.lineno }
                | tIVAR { result = s(:ivar, val[0].to_sym).line lexer.lineno }
                | tCVAR { result = s(:cvar, val[0].to_sym).line lexer.lineno }
                | backref

          symbol: ssym
                | dsym

            ssym: tSYMBEG sym
                    {
                      lexer.lex_state = EXPR_END
                      result = new_symbol val
                    }
                | tSYMBOL
                    {
                      lexer.lex_state = EXPR_END
                      result = new_symbol val
                    }

             sym: fname | tIVAR | tGVAR | tCVAR

            dsym: tSYMBEG string_contents tSTRING_END
                    {
                      _, result, _ = val

                      lexer.lex_state = EXPR_END

                      result ||= s(:str, "").line lexer.lineno

                      case result.sexp_type
                      when :dstr then
                        result.sexp_type = :dsym
                      when :str then
                        result = s(:lit, result.last.to_sym).line result.line
                      when :evstr then
                        result = s(:dsym, "", result).line result.line
                      else
                        debug20 26, val, result
                      end
                    }

#if V == 20
         numeric: tINTEGER
                | tFLOAT
                | tUMINUS_NUM tINTEGER =tLOWEST
#else
         numeric: simple_numeric
                | tUMINUS_NUM simple_numeric
#endif
                    {
                      result = -val[1] # TODO: pt_testcase
#if V == 20
                    }
                | tUMINUS_NUM tFLOAT   =tLOWEST
                    {
                      result = -val[1] # TODO: pt_testcase
#endif
                    }

#if V >= 21
  simple_numeric: tINTEGER
                | tFLOAT
                | tRATIONAL
                | tIMAGINARY

#endif
   user_variable: tIDENTIFIER
                | tIVAR
                | tGVAR
                | tCONSTANT
                | tCVAR

keyword_variable: kNIL      { result = s(:nil).line lexer.lineno }
                | kSELF     { result = s(:self).line lexer.lineno }
                | kTRUE     { result = s(:true).line lexer.lineno }
                | kFALSE    { result = s(:false).line lexer.lineno }
                | k__FILE__ { result = s(:str, self.file).line lexer.lineno }
                | k__LINE__ { result = s(:lit, lexer.lineno).line lexer.lineno }
                | k__ENCODING__
                    {
                      l = lexer.lineno
                      result =
                        if defined? Encoding then
                          s(:colon2, s(:const, :Encoding).line(l), :UTF_8).line l
                        else
                          s(:str, "Unsupported!").line l
                        end
                    }

         var_ref: user_variable
                    {
                      var = val[0]
                      result = Sexp === var ? var : self.gettable(var)
                    }
                | keyword_variable
                    {
                      var = val[0]
                      result = Sexp === var ? var : self.gettable(var)
                    }

         var_lhs: user_variable
                    {
                      result = self.assignable val[0]
                    }
                | keyword_variable
                    {
                      result = self.assignable val[0]
                      debug20 29, val, result
                    }

         backref: tNTH_REF  { result = s(:nth_ref,  val[0]).line lexer.lineno }
                | tBACK_REF { result = s(:back_ref, val[0]).line lexer.lineno }

      superclass: tLT
                    {
                      lexer.lex_state = EXPR_BEG
                      lexer.command_start = true
                    }
                    expr_value term
                    {
                      result = val[2]
                    }
                | none
                    {
                      result = nil
                    }

       f_arglist: tLPAREN2 f_args rparen
                    {
                      result = val[1]
                      self.lexer.lex_state = EXPR_BEG
                      self.lexer.command_start = true
                    }
#if V >= 27
                | tLPAREN2 f_arg tCOMMA args_forward rparen
                    {
                      result = args val

                      self.lexer.lex_state = EXPR_BEG
                      self.lexer.command_start = true
                    }
                | tLPAREN2 args_forward rparen
                    {
                      result = args val

                      self.lexer.lex_state = EXPR_BEG
                      self.lexer.command_start = true
                    }
#endif
                |   {
                      result = self.in_kwarg
                      self.in_kwarg = true
                      self.lexer.lex_state |= EXPR_LABEL
                    }
                    f_args term
                    {
                      kwarg, args, _ = val

                      self.in_kwarg = kwarg
                      result = args
                      lexer.lex_state     = EXPR_BEG
                      lexer.command_start = true
                    }

       args_tail: f_kwarg tCOMMA f_kwrest opt_f_block_arg
                    {
                      result = args val
                    }
                | f_kwarg opt_f_block_arg
                    {
                      result = args val
                    }
                | f_kwrest opt_f_block_arg
                    {
                      result = args val
                    }
#if V >= 27
                | f_no_kwarg opt_f_block_arg
                    {
                      result = args val
                    }
#endif
                | f_block_arg

   opt_args_tail: tCOMMA args_tail
                    {
                      result = val[1]
                    }
                |
                    {
                      result = nil
                    }

          f_args: f_arg tCOMMA f_optarg tCOMMA f_rest_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_optarg tCOMMA f_rest_arg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_optarg              opt_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_optarg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA            f_rest_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_arg tCOMMA f_rest_arg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_arg                             opt_args_tail
                    {
                      result = args val
                    }
                |           f_optarg tCOMMA f_rest_arg opt_args_tail
                    {
                      result = args val
                    }
                | f_optarg tCOMMA f_rest_arg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                |           f_optarg                opt_args_tail
                    {
                      result = args val
                    }
                | f_optarg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                |                        f_rest_arg opt_args_tail
                    {
                      result = args val
                    }
                |           f_rest_arg tCOMMA f_arg opt_args_tail
                    {
                      result = args val
                    }
                |                                       args_tail
                    {
                      result = args val
                    }
                |
                    {
                      result = args val
                    }

#if V >= 27
    args_forward: tBDOT3
                    {
                      result = s(:forward_args).line lexer.lineno
                    }
#endif

       f_bad_arg: tCONSTANT
                    {
                      yyerror "formal argument cannot be a constant"
                    }
                | tIVAR
                    {
                      yyerror "formal argument cannot be an instance variable"
                    }
                | tGVAR
                    {
                      yyerror "formal argument cannot be a global variable"
                    }
                | tCVAR
                    {
                      yyerror "formal argument cannot be a class variable"
                    }

      f_norm_arg: f_bad_arg
                | tIDENTIFIER
                    {
                      identifier = val[0].to_sym
                      self.env[identifier] = :lvar

                      result = identifier
                    }

#if V >= 22
      f_arg_asgn: f_norm_arg

      f_arg_item: f_arg_asgn
                | tLPAREN f_margs rparen
                    {
                      result = val[1]
                    }
#else
      f_arg_item: f_norm_arg
                | tLPAREN f_margs rparen
                    {
                      result = val[1]
                    }
#endif

           f_arg: f_arg_item
                    {
                      arg, = val

                      case arg
                      when Symbol then
                        result = s(:args, arg).line lexer.lineno
                      when Sexp then
                        result = arg
                      else
                        debug20 32
                        raise "Unknown f_arg type: #{val.inspect}"
                      end
                    }
                | f_arg tCOMMA f_arg_item
                    {
                      list, _, item = val

                      if list.sexp_type == :args then
                        result = list
                      else
                        result = s(:args, list).line list.line
                      end

                      result << item
                    }

#if V == 20
            f_kw: tLABEL arg_value
#else
         f_label: tLABEL

            f_kw: f_label arg_value
#endif
                    {
                      # TODO: new_kw_arg
                      (label, line), arg = val

                      identifier = label.to_sym
                      self.env[identifier] = :lvar

                      kwarg  = s(:kwarg, identifier, arg).line line
                      result = s(:array, kwarg).line line
                    }
#if V >= 21
                | f_label
                    {
                      (label, line), = val

                      id = label.to_sym
                      self.env[id] = :lvar

                      result = s(:array, s(:kwarg, id).line(line)).line line
                    }
#endif

#if V == 20
      f_block_kw: tLABEL primary_value
#else
      f_block_kw: f_label primary_value
#endif
                    {
                      # TODO: new_kw_arg
                      (label, line), expr = val
                      id = label.to_sym
                      self.env[id] = :lvar

                      result = s(:array, s(:kwarg, id, expr).line(line)).line line
                    }
#if V >= 21
                | f_label
                    {
                      # TODO: new_kw_arg
                      (label, line), = val
                      id = label.to_sym
                      self.env[id] = :lvar

                      result = s(:array, s(:kwarg, id).line(line)).line line
                    }
#endif

   f_block_kwarg: f_block_kw
                | f_block_kwarg tCOMMA f_block_kw
                    {
                      list, _, item = val
                      result = list << item.last
                    }

         f_kwarg: f_kw
                | f_kwarg tCOMMA f_kw
                    {
                      result = args val
                    }

     kwrest_mark: tPOW
                | tDSTAR

#if V >= 27
      f_no_kwarg: kwrest_mark kNIL
                    {
                      result = :"**nil"
                    }
#endif

        f_kwrest: kwrest_mark tIDENTIFIER
                    {
                      name = val[1].to_sym
                      self.assignable name
                      result = :"**#{name}"
                    }
                | kwrest_mark
                    {
                      result = :"**"
                      self.env[result] = :lvar # TODO: needed?!?
                    }

#if V == 20
           f_opt: tIDENTIFIER tEQL arg_value
#elif V == 21
           f_opt: f_norm_arg tEQL arg_value
#else
           f_opt: f_arg_asgn tEQL arg_value
#endif
                    {
                      result = self.assignable val[0], val[2]
                      # TODO: detect duplicate names
                    }

#if V == 20
     f_block_opt: tIDENTIFIER tEQL primary_value
#elif V == 21
     f_block_opt: f_norm_arg tEQL primary_value
#else
     f_block_opt: f_arg_asgn tEQL primary_value
#endif
                    {
                      result = self.assignable val[0], val[2]
                    }

  f_block_optarg: f_block_opt
                    {
                      optblk, = val
                      result = s(:block, optblk).line optblk.line
                    }
                | f_block_optarg tCOMMA f_block_opt
                    {
                      optarg, _, optblk = val
                      result = optarg
                      result << optblk
                    }

        f_optarg: f_opt
                    {
                      opt, = val
                      result = s(:block, opt).line opt.line
                    }
                | f_optarg tCOMMA f_opt
                    {
                      result = self.block_append val[0], val[2]
                    }

    restarg_mark: tSTAR2 | tSTAR

      f_rest_arg: restarg_mark tIDENTIFIER
                    {
                      # TODO: differs from parse.y - needs tests
                      name = val[1].to_sym
                      self.assignable name
                      result = :"*#{name}"
                    }
                | restarg_mark
                    {
                      name = :"*"
                      self.env[name] = :lvar
                      result = name
                    }

     blkarg_mark: tAMPER2 | tAMPER

     f_block_arg: blkarg_mark tIDENTIFIER
                    {
                      identifier = val[1].to_sym

                      self.env[identifier] = :lvar
                      result = "&#{identifier}".to_sym
                    }

 opt_f_block_arg: tCOMMA f_block_arg
                    {
                      result = val[1]
                    }
                |
                    {
                      result = nil
                    }

       singleton: var_ref
                | tLPAREN2
                    {
                      lexer.lex_state = EXPR_BEG
                    }
                    expr rparen
                    {
                      result = val[2]
                      yyerror "Can't define single method for literals." if
                        result.sexp_type == :lit
                    }

      assoc_list: none
                    {
                      result = s(:array).line lexer.lineno
                    }
                | assocs trailer

          assocs: assoc
                | assocs tCOMMA assoc
                    {
                      list = val[0].dup
                      more = val[2].sexp_body
                      list.push(*more) unless more.empty?
                      result = list
                      result.sexp_type = :hash
                    }

           assoc: arg_value tASSOC arg_value
                    {
                      v1, _, v2 = val
                      result = s(:array, v1, v2).line v1.line
                    }
                | tLABEL arg_value
                    {
                      (label, line), arg = val

                      lit = s(:lit, label.to_sym).line line
                      result = s(:array, lit, arg).line line
                    }
#if V >= 22
                | tSTRING_BEG string_contents tLABEL_END arg_value
                    {
                      _, sym, _, value = val
                      sym.sexp_type = :dsym
                      result = s(:array, sym, value).line sym.line
                    }
#endif
                | tDSTAR arg_value
                    {
                      _, arg = val
                      line = arg.line
                      result = s(:array, s(:kwsplat, arg).line(line)).line line
                    }

       operation: tIDENTIFIER | tCONSTANT | tFID
      operation2: tIDENTIFIER | tCONSTANT | tFID | op
      operation3: tIDENTIFIER | tFID | op
    dot_or_colon: tDOT | tCOLON2
         call_op: tDOT
#if V >= 23
                | tLONELY # TODO: rename tANDDOT?
#endif

        call_op2: call_op
                | tCOLON2

       opt_terms:  | terms
          opt_nl:  | tNL
          rparen: opt_nl tRPAREN
        rbracket: opt_nl tRBRACK
#if V >= 27
          rbrace: opt_nl tRCURLY
#endif
         trailer:  | tNL | tCOMMA

            term: tSEMI { yyerrok }
                | tNL

           terms: term
                | terms tSEMI { yyerrok }

            none: { result = nil; }
end

---- inner

require "ruby_lexer"
require "ruby_parser_extras"
include RubyLexer::State::Values

# :stopdoc:

# Local Variables: **
# racc-token-length-max:14 **
# End: **
