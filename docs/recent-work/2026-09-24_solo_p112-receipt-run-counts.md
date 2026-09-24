# Receipt schema version 2 with run counts

Shipped P112 with ship-sop P34, the third item of the day after P110 (merge)
and P111 (reviewer scope by path). `sop_receipt_valid` accepts schema version 1
unchanged and version 2, whose reviewer entries must carry launches (at least
one), rechecks and block_rounds (never more than the runs), and may carry a
usage object or null. Three hook fixtures pin it (104 in the suite); all nine
suites and shellcheck pass; CI green on main. Both user-scope hook libraries
refreshed (Claude via install-hooks, Codex via the sync script).

Why: receipts carried no cost field, so the 24 September gate-cost figure was an
estimate. The counts are the measured proxy the next reviewer-default decision
can rest on.
