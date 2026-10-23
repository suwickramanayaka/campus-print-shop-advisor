# Campus Print Shop Advisor

A Sri Lankan campus printing-shop assignment written in SWI-Prolog. It recommends printing options based on customer requirements, budget, stock and completion deadlines.

## Start here

- [Setup and usage](prolog-assignment/README.md)
- [Demo guide and viva preparation](prolog-assignment/DEMO_GUIDE.md)
- [Design specification](prolog-assignment/DESIGN_SPEC.md)
- [Four-slide presentation with Sinhala speaker notes](prolog-assignment/presentation/Campus_Print_Shop_Advisor.pptx)
- [Captured example sessions](prolog-assignment/sample_runs.txt)

## Run

Install SWI-Prolog, then run:

```sh
cd prolog-assignment
swipl -q -s main.pl
```

At the Prolog prompt, enter `start.` for the console or `start_web.` for the browser interface at http://localhost:8080. Both interfaces can share one Prolog process. Run only one application process against the saved database.

## Test

```sh
cd prolog-assignment
swipl -g run_tests -t halt tests.pl
```

The project includes 47 unit tests. The core has 256 physical lines, excluding interfaces and tests. Prices, production speeds and daily 09:00–17:00 shop hours are educational assumptions. All schedule times use Sri Lanka time.

The source and documentation are in `prolog-assignment/`. `Prompt.txt` contains the original assignment brief. Temporary presentation build files and duplicate ZIP archives are excluded from version control.
