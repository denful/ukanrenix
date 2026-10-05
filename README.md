<p align="right">
  <a href="https://dendritic.oeiuwq.com/sponsor"><img src="https://img.shields.io/badge/sponsor-vic-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/></a>
  <a href="https://deepwiki.com/denful/ukanrenix"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <a href="https://github.com/denful/ukanrenix/releases"><img src="https://img.shields.io/github/v/release/denful/ukanrenix?style=plastic&logo=github&color=purple"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/denful/ukanrenix" alt="License"/></a>
  <a href="https://github.com/denful/ukanrenix/actions"><img src="https://github.com/denful/ukanrenix/actions/workflows/test.yml/badge.svg" alt="CI Status"/></a>
</p>

> ukanrenix and [vic](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://dendritic.oeiuwq.com) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://dendritic.oeiuwq.com/sponsor)


<table>
<tr>
<td>


# ukanrenix

ukanrenix is a pure-Nix μKanren implementation — relational and logic programming embedded directly in the Nix expression language.

[Gen](https://gen.wtf) ecosystem integrations live in [`gen/`](./gen/) via [`gen-integration.nix`](./gen-integration.nix).

CI [tests](./tests/) — 95 passing.


</td>

<td>

### Documentation: [ukanrenix.denful.dev](https://ukanrenix.denful.dev)

</td>
</tr>
</table>

---


## Design

**μKanren in pure Nix.** The entire relational engine — unification, substitution, stream interleaving — is expressed as Nix functions. No C extensions, no external runtimes, no IFD. `import ./. {}` is the only entry point.

**Unification over native Nix types.** The unifier handles Nix scalars, lists, and attrsets natively. Logic variables unify with any Nix value, so query results come back as ordinary Nix data — no unwrapping step.

**Lazy streams for divergence safety.** Conjunctions and disjunctions thread through a lazy stream representation (`mplus`, `bind`, `streamTake`). Interleaving prevents complete divergence on infinite search spaces and makes depth-bounded queries predictable.

**Weighted search via Tropical semiring.** `semiring.nix` layers a cost model over the base engine. Goals carry weights; `wrun` and `wrunFull` return answers ranked by total path cost. This turns the relational engine into a shortest-path enumerator over symbolic programs.

**Memoized bottom-up enumeration.** `bank.nix` provides `defBank` and `pruneBy` for tabling: previously computed sub-goal results are cached and reused across branches, enabling efficient enumeration of structured terms without exponential blowup.

**Multi-stage evaluation with holes.** `staged.nix` exposes `evalExpr`, an evaluator that treats `hole` terms as unknowns. Partial programs can be evaluated, residualised, and completed by search — bridging symbolic and concrete evaluation.

**Constraint Handling Rules.** `chr.nix` adds a CHR layer (`constrain`, `chrRun`) on top of unification. Constraints are fired by rule heads, enabling type guards (`typeOf`), disequality (`diseq`), and user-defined propagation rules that interact with the unifier.

**Gen ecosystem integration.** The `gen/` modules connect ukanrenix to the gen-types, gen-merge, gen-select, and gen-scope protocols. Backward synthesis (`synthFromModules`), selector synthesis returning gen-select native values, and CHR type guards are all available when the gen deps are provided.


## Usage

```nix
let ukanren = import (fetchTarball "github:denful/ukanrenix") {};
in ukanren.run 3 (q: ukanren.eq q 42)
# => [42]
```

Gen integration:

```nix
let ukanren = import ./gen-integration.nix { inherit genMerge genSelect genTypes genScope; };
```
