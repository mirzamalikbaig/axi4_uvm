# AXI4 UVM Test Scenario Summary

Source: uploaded result/regression_summary.txt, Synopsys VCS run October 16, 2026, seed 1.
This is a **single simulation containing 12 directed scenarios**, not a multi-seed regression.

| # | Scenario | Completion in simulation log |
|---:|---|---|
| 1 | Memory setup: writes to addresses 100 and 200 | Followed by successful readback tests |
| 2 | Different-ID reads (out-of-order response) | 275000 ps |
| 3 | Same-ID reads (in-order response) | 385000 ps |
| 4 | Different-ID writes (out-of-order B response) | 535000 ps |
| 5 | Same-ID writes (in-order B response) | 685000 ps |
| 6 | Write readback | 875000 ps |
| 7 | Four-beat WRAP write | 1005000 ps |
| 8 | Four-beat WRAP read | 1195000 ps |
| 9 | FIXED write | 1375000 ps |
| 10 | FIXED read | 1605000 ps |
| 11 | Multi-beat INCR write | 1735000 ps |
| 12 | Multi-beat INCR read | 1925000 ps |

**Final test message:** All AXI READ, WRITE, WRAP, FIXED and multi-beat INCR tests completed.

**Functional coverage:** 98.15%  
**UVM errors:** 0  
**UVM fatals:** 0  
**UVM warnings:** 0

Full raw execution output was supplied separately in the uploaded result.zip. This summary is evidence of the one completed seed, not proof of a five-seed regression.
