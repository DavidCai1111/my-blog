---
title: '[译]对于 zk-SNARKs 运行的简介'
date: 2022-02-27 08:59:52
tags:
---

在过去十年中，普适的简洁零知识证明或许是密码学领域最有影响力的发展方向之一，通常简称为 zk-SNARKs（zero knowledge succinct arguments of knowledge）。zk-SNARKs 可以让你为执行的计算生成一些证明（proof），虽然这些证明的生成可能会耗费非常多的算力，但是却可以被很快地验证。并且这些证明还拥有“零知识”的特性，即证明中会隐藏计算中的输入信息。

举个例子，你可以给出一个关于你确实知道某个密码数字的证明：你会把这个数字加到字符 `cow` 后面，然后执行 100 万次 SHA256 哈希，最终结果会以 `0x57d00485aa` 开头。在 zk-SNARKs 的应用场景里，验证者可以以远比执行 100 万次哈希快的时间验证你是否确实知道你所说的密码数字，并且该数字不会暴露给验证者。

在区块链中，zk-SNARKs 有两个非常有用的应用场景：

- 可扩展性（scalability）：如果一个区块需要花很多时间才能被验证，那么某人可以预先为其生成证明，然后其他人只需要快速地验证生成的证明即可
- 隐私性（Privacy）：你可以在隐藏具体收到资产的收款路径的情况下，声明你的确拥有某些资产

不过 zk-SNARKs 是非常复杂的。在 2014 - 2017 年间，它还仅仅只是被称为“魔法数学（moon math）”。不过好消息是，此后随着人们的研究越来越深，它的协议也被优化得越来越简单。这篇文章将会在只要求读者拥有中等水平的数学知识的前提下，简单叙述 zk-SNARKs 是如何工作的。

我们将重点关注可扩展性方便。在解决了可扩展性的问题后，隐私性的问题也会跟着迎刃而解，我们将会在文章的最后再讨论隐私性。

## 为什么 zk-SNARKs “必须”是复杂的

让我们回到刚才的例子：我们有一个密码（`cow` + `密码数字`），我们将其执行一次 SHA256 ，然后将哈希结果再哈希 99,999,999 次，得到了最终结果，记录下起始的哈希。计算量非常之大。

一个“简洁的（succinct）”证明意味着：随着生成证明的计算量不断增大，验证这个证明所需的计算量只会相对缓慢增大。所以，如果我们想要生成一个“简洁的“证明，那么我们肯定不能要求验证者去做上述同样次数的哈希。所以验证者应该只需要窥探到完整计算的一部分，而不是所有步骤。

一个能自然而然想到的方法就是随机抽样验证：我们从 100 万次哈希中抽样出 500 次，然后验证哈希结果，如果都是正确的话，那么我就假设其余的计算都是正确的。

通过 [Fiat-Shamir 变换](https://en.wikipedia.org/wiki/Fiat%E2%80%93Shamir_heuristic)，上述过程可以变成一个非交互式（non-interactive）的证明：验证者提供计算结果的默克尔树根，基于这颗默克尔树，伪随机地（pseudorandomly）选择 500 个索引值（抽样出其中 500 次计算），然后要求提供结果默克尔树中，这 500 个索引值对应的默克尔证明。其中的关键点是，证明者在给出默克尔树根前，不能够预先知道抽样的索引值。如果证明者在给出默克尔树根后还想要进行欺诈，那么改变默克尔树中的叶子值的话，提交的默克尔树根就会对应不上。

不幸的是，这样简单的进行随机抽样检查计算过程，有一个致命的缺陷：这样的计算本质上是脆弱的。如果欺诈者在证明的计算过程中修改了一个比特，那么一开始就会生成一个完全不同的结果（译者注：在上述例子中，就是一开始就会给出一个完全不同的默克尔树根）。随机抽样的验证者是大概率验证不出的（译者注：例如欺诈者只修改一百万步哈希计算中的一步的计算结果，那么随机抽样 500 次将很难命中，如下图所示）。

![1](https://vitalik.ca/images/snarks-files/randomsample.png)

这正是 zk-SNARKs 协议需要解决的问题之一：如何让一个验证者在不验证所有计算步骤的前提下，验证每一步计算都是正确的。

## 多项式

多项式是拥有如下格式的一种特殊代数表达式：

![2](https://static.cnodejs.org/FiVGBwscV3nrzXygcgqAecDBNxr0)

是有限个 c * x^k 的累加。

多项式包含许多特性。不过此处我们仅关心其中一种：多项式可以在一个数学表达式中包含无限的信息（因为多项式中的累加项是无限的）。例如上述的第四个多项式例子中，包含了 816 个 [tau](https://math.fandom.com/wiki/Tau_(constant)) ，并且如果需要包含更多，也是能很轻松做到的。

更进一步，一个多项式之间的等式，可以代表无限多个对应数字的等式。例如，等式：A(x) + B(x) = C(x) 。如果这个多项式等式成立，那么以下等式也同样成立：

![3](https://static.cnodejs.org/FgN6EVtw5C-LZxpzCiLqmkk59-Z2)

同样也可以带入到坐标系中。你可以把所有待检查的数字都组装进一个多项式中。举个例子，你想要检查：

- 12 + 1 = 13
- 10 + 8 = 18
- 15 + 8 = 23
- 15 + 13 = 28

你可以使用[拉格朗日插值法](https://en.wikipedia.org/wiki/Lagrange_polynomial)将一个点值表示的多项式，例如 A(x) 在 (0, 1, 2, 3) 处值为 (12, 10, 15, 15) ，B(x) 在 (0, 1, 2, 3) 处值为 (1, 8, 8, 13) ，转换为系数形式，具体表示如下：

![4](https://static.cnodejs.org/FgIrvks6VhjdCUhpUSZycXBh1PuV)

这三个多项式等式是完全符合上述图（3）等式的。

## 多项式之间的比较

你可以使用同一个多项式，来检查多项式在连续输入值之间输出结果的关系。例如，你想检查的是：对于一个多项式 F ，x 取值范围在整数 {0,1,...98} ，多项式满足 F(x + 2) = F(x + 1) + F(x) （所以如果 F(0) = F(1) = 1 ，那么 F(100) 就是第 100 个斐波那契数）。

对于给出的多项式来说，由于 x 的取值可能不在 {0,1,...98} 之间，那么 F(x + 2) - F(x + 1) - F(x) 可能也就不一定为零。所以，我们需要更进一步。一般来说，如果一个多项式 P 在 S = {x1, x2, ... xn} 处等于零，那么它就可以被表示为 P(x) = Z(x) * H(x) ，其中 Z(x) = (x - x1) * (x - x2) * .... * (x - xn) ，并且 H(x) 也是一个多项式。换句话说，这个多项式可以表示成，在于其为零值的点的 (x - xn) 的乘法累计结果与另一个多项式的乘积。

对于多项式长除法（long division）有一个很好的推论：[因式定理](https://en.wikipedia.org/wiki/Factor_theorem)。我们知道，当我们将 P(x) 除以 Z(x) 时，我们会得到一个商 Q(x) 和一个余数 R(x)，即 P(x) = Z(x) * Q(x) + R(x)，此处的 R(x)（由于是余数）一定是比 Z(x)（由于是被除数）小的。由于我们知道 P 在取值范围 S 上等于 0 ，所以在取值范围 S 上，R(x) 也必须等于 0 。所以在取值范围 S 处，Q(x) = H(x) 。

回到我们上述的满足斐波那契数的多项式 F 上，那么我可以说服你，我提供的 F 确实是满足的条件的，如果在 P(x) = F(x + 2) - F(x + 1) - F(x) ，在我提供的以下 H(x) 和 Z(x) 等式下，为零：

![5](https://static.cnodejs.org/FrylvJ9_DpKyRHOPksEWHhtM2nbB)

至此为止，我们把一个有 100 步的计算（即需要计算出第 100 个斐波那契数）组装进入了一个多项式等式。所以基于这个技术，你可以将包含任意大数字的任意步骤计算放入多项式中。

所以，有比逐个检查因子更快的验证方法吗？

## 多项式承诺

答案就是：多项式承诺。我们可以将多项式承诺理解为多项式的“哈希”。你可以通过检查它们“哈希”间的等式，来检查两个多项式是否相等。不同的多项式承诺类型，会提供不同的可检查等式类型。

对于大多数多项式承诺类型，你都可以通过它们进行如下检查（com(P) 即指多项式 P 的承诺）：

- 相加：给定 com(P)，com(Q)，和 com(R)，检查是否 P + Q = R
- 相乘：给定 com(P)，com(Q)，和 com(R)，检查是否 P * Q = R
- 某一点的值：给定 com(P)，w，z，和一个补充证明 Q，验证 P(w) = z

我们需要将上述这些等式特性糅合在一起使用。如果你可以验证相加或相乘，那么你就可以验证给定点的值：P(w) = z ，你可以构造 Q(x) = (P(x) - z) / (x - w) ，然后检查 Q(x) * (x - w) + z = P(x) 。如果 Q(x) 存在，那么 P(x) - z = Q(x) * (x - w) ，这就意味着 P(x) 在 w 处 等于 z 。

[Schwartz-Zippel 引理](https://en.wikipedia.org/wiki/Schwartz%E2%80%93Zippel_lemma)表示， 如果一些多项式等式在某些随机点验证结果都是真，那么几乎在所有点都会是真。所以，我们可以使用如下的交互来验证 P(x + 2) - P(x + 1) - P(x) = Z(x) * H(x) ：

![6](https://vitalik.ca/images/snarks-files/SchwartzZippel.png)

根据上文所表述的，我们可以通过 [Fiat-Shamir 变换](https://en.wikipedia.org/wiki/Fiat%E2%80%93Shamir_heuristic)来让上述过程变成非交互式：证明者自己通过 `r = hash(com(P), com(H))` 计算出 `r` （hash 可以是任意哈希函数），所以当证明者在选择 `P` 和 `H` 时，他并不知道 `r` （即是通过哈希生成的“随机值”），所以也没办法通过“挑选” `P` 和 `H` 使之符合某个 `r`。

## 小结

- zk-SNARKs 是困难的，因为它允许验证者无需重放计算的每一步，而可以验证一个拥有百万次步骤的计算结果
- 我们将计算编码入了一个多项式
- 一个多项式可以包含任意多的信息，并且一个多项式表达式（例如 P(x + 2) - P(x + 1) - P(x) = Z(x) * H(x)）可以表示任意数量的等式
- 如果你验证了多项式之间的等式，那么你就隐式地验证了所有数字的等式（将其带入 x 坐标系）
- 我们使用多项式承诺，来作为多项式的一种特殊“哈希”，这样一来，即使原本的多项式很大，我们也可以在很短的时间内验证它们之间的等式

## 多项式承诺是如何工作的

There are three major schemes that are widely used at the moment: bulletproofs, Kate and FRI.

Here is a description of Kate commitments by Dankrad Feist: https://dankradfeist.de/ethereum/2020/06/16/kate-polynomial-commitments.html
Here is a description of bulletproofs by the curve25519-dalek team: https://doc-internal.dalek.rs/bulletproofs/notes/inner_product_proof/index.html, and here is an explanation-in-pictures by myself: https://twitter.com/VitalikButerin/status/1371844878968176647
Here is a description of FRI by... myself: https://vitalik.ca/general/2017/11/22/starks_part_2.html
Whoa, whoa, take it easy. Try to explain one of them simply, without shipping me off to even more scary links
To be honest, they're not that simple. There's a reason why all this math did not really take off until 2015 or so.

Please?
In my opinion, the easiest one to understand fully is FRI (Kate is easier if you're willing to accept elliptic curve pairings as a "black box", but pairings are really complicated, so altogether I find FRI simpler).

Here is how a simplified version of FRI works (the real protocol has many tricks and optimizations that are missing here for simplicity). Suppose that you have a polynomial  with degree . The commitment to  is a Merkle root of a set of evaluations to  at some set of pre-selected coordinates (eg. , though this is not the most efficient choice). Now, we need to add something extra to prove that this set of evaluations actually is a degree  polynomial.

Let  be the polynomial only containing the even coefficients of , and  be the polynomial only containing the odd coefficients of . So if , then  and  (note that the degrees of the coefficients get "collapsed down" to the range ).

Notice that  (if this isn't immediately obvious to you, stop and think and look at the example above until it is).

We ask the prover to provide Merkle roots for  and . We then generate a random number  and ask the prover to provide a "random linear combination" .

We pseudorandomly sample a large set of indices (using the already-provided Merkle roots as the seed for the randomness as before), and ask the prover to provide the Merkle branches for , ,  and  at these indices. At each of these provided coordinates, we check that:

 actually does equal
 actually does equal
If we do enough checks, then we can be convinced that the "expected" values of  are different from the "provided" values in at most, say, 1% of cases.

Notice that  and  both have degree . Because  is a linear combination of  and ,  also has degree . And this works in reverse: if we can prove  has degree , then the fact that it's a randomly chosen combination prevents the prover from choosing malicious  and  with hidden high-degree coefficients that "cancel out", so  and  must both be degree , and because , we know that  must have degree .

From here, we simply repeat the game with , progressively "reducing" the polynomial we care about to a lower and lower degree, until it's at a sufficiently low degree that we can check it directly.



As in the previous examples, "Bob" here is an abstraction, useful for cryptographers to mentally reason about the protocol. In reality, Alice is generating the entire proof herself, and to prevent her from cheating we use Fiat-Shamir: we choose each randomly samples coordinate or r value based on the hash of the data generated in the proof up until that point.

A full "FRI commitment" to  (in this simplified protocol) would consist of:

The Merkle root of evaluations of
The Merkle roots of evaluations of , ,
The randomly selected branches of , , ,  to check  is correctly "reduced from"
The Merkle roots and randomly selected branches just as in steps (2) and (3) for successively lower-degree reductions  reduced from ,  reduced from , all the way down to a low-degree  (this gets repeated  times in total)
The full Merkle tree of the evaluations of  (so we can check it directly)
Each step in the process can introduce a bit of "error", but if you add enough checks, then the total error will be low enough that you can prove that  equals a degree  polynomial in at least, say, 80% of positions. And this is sufficient for our use cases: if you want to cheat in a zk-SNARK, you would need to make a polynomial commitment for a fractional value, and the set of evaluations for any fractional expression would differ from the evaluations for any real degree  polynomial in so many positions that any attempt to make a FRI commitment to them would fail.

Also, you can check carefully that the total number and size of the objects in the FRI commitment is logarithmic in the degree, so for large polynomials, the commitment really is much smaller than the polynomial itself.

To check equations between different polynomial commitments of this type (eg. check  given FRI commitments to ,  and ), simply randomly select many indices, ask the prover for Merkle branches at each of those indices for each polynomial, and verify that the equation actually holds true at each of those positions.

The above description is a highly inefficient protocol; there is a whole host of algebraic tricks that can increase its efficiency by a factor of something like a hundred, and you need these tricks if you want a protocol that is actually viable for, say, use inside a blockchain transaction. In particular, for example,  and  are not actually necessary, because if you choose your evaluation points very cleverly, you can reconstruct the evaluations of  and  that you need directly from evaluations of . But the above description should be enough to convince you that a polynomial commitment is fundamentally possible.

Finite fields
In the descriptions above, there was a hidden assumption: that each individual "evaluation" of a polynomial was small. But when we are dealing with polynomials that are big, this is clearly not true. If we take our example from above, , that encodes 816 digits of tau, and evaluate it at , you get.... an 816-digit number containing all of those digits of tau. And so there is one more thing that we need to add. In a real implementation, all of the arithmetic that we are doing here would not be done using "regular" arithmetic over real numbers. Instead, it would be done using modular arithmetic.

We redefine all of our arithmetic operations as follows. We pick some prime "modulus" p. The % operator means "take the remainder of": , , etc (note that the answer is always non-negative, so for example ). We redefine

 %

 %

 %

 %

 %

The above rules are all self-consistent. For example, if , then:

 (as  % )
 (as  % )
 (as () %  % )
More complex identities such as the distributive law also hold:  and  both evaluate to . Even formulas like  =  are still true in this new kind of arithmetic.

Division is the hardest part; we can't use regular division because we want the values to always remain integers, and regular division often gives non-integer results (as in the case of ). We get around this problem using Fermat's little theorem, which states that for any nonzero , it holds that  % . This implies that  gives a number which, if multiplied by  one more time, gives , and so we can say that  (which is an integer) equals . A somewhat more complicated but faster way to evaluate this modular division operator is the extended Euclidean algorithm, implemented in python here.



Because of how the numbers "wrap around", modular arithmetic is sometimes called "clock math"


With modular math we've created an entirely new system of arithmetic, and it's self-consistent in all the same ways traditional arithmetic is self-consistent. Hence, we can talk about all of the same kinds of structures over this field, including polynomials, that we talk about in "regular math". Cryptographers love working in modular math (or, more generally, "finite fields") because there is a bound on the size of a number that can arise as a result of any modular math calculation - no matter what you do, the values will not "escape" the set . Even evaluating a degree-1-million polynomial in a finite field will never give an answer outside that set.

What's a slightly more useful example of a computation being converted into a set of polynomial equations?
Let's say we want to prove that, for some polynomial , , without revealing the exact value of . This is a common use case in blockchain transactions, where you want to prove that a transaction leaves a balance non-negative without revealing what that balance is.

We can construct a proof for this with the following polynomial equations (assuming for simplicity ):

 across the range
 across the range
The latter two statements can be restated as "pure" polynomial equations as follows (in this context ):

 (notice the clever trick:  if and only if )
The idea is that successive evaluations of  build up the number bit-by-bit: if , then the sequence of evaluations going up to that point would be: . In binary, 1 is 1, 3 is 11, 6 is 110, 13 is 1101; notice how  keeps adding one bit to the end as long as  is zero or one. Any number within the range  can be built up over 64 steps in this way, any number outside that range cannot.

Privacy
But there is a problem: how do we know that the commitments to  and  don't "leak" information that allows us to uncover the exact value of , which we are trying to keep hidden?

There is some good news: these proofs are small proofs that can make statements about a large amount of data and computation. So in general, the proof will very often simply not be big enough to leak more than a little bit of information. But can we go from "only a little bit" to "zero"? Fortunately, we can.

Here, one fairly general trick is to add some "fudge factors" into the polynomials. When we choose , add a small multiple of  into the polynomial (that is, set  for some random ). This does not affect the correctness of the statement (in fact,  evaluates to the same values as  on the coordinates that "the computation is happening in", so it's still a valid transcript), but it can add enough extra "noise" into the commitments to make any remaining information unrecoverable. Additionally, in the case of FRI, it's important to not sample random points that are within the domain that computation is happening in (in this case ).

Can we have one more recap, please??
The three most prominent types of polynomial commitments are FRI, Kate and bulletproofs.
Kate is the simplest conceptually but depends on the really complicated "black box" of elliptic curve pairings.
FRI is cool because it relies only on hashes; it works by successively reducing a polynomial to a lower and lower-degree polynomial and doing random sample checks with Merkle branches to prove equivalence at each step.
To prevent the size of individual numbers from blowing up, instead of doing arithmetic and polynomials over the integers, we do everything over a finite field (usually integers modulo some prime p)
Polynomial commitments lend themselves naturally to privacy preservation because the proof is already much smaller than the polynomial, so a polynomial commitment can't reveal more than a little bit of the information in the polynomial anyway. But we can add some randomness to the polynomials we're committing to to reduce the information revealed from "a little bit" to "zero".
What research questions are still being worked on?
Optimizing FRI: there are already quite a few optimizations involving carefully selected evaluation domains, "DEEP-FRI", and a whole host of other tricks to make FRI more efficient. Starkware and others are working on this.
Better ways to encode computation into polynomials: figuring out the most efficient way to encode complicated computations involving hash functions, memory access and other features into polynomial equations is still a challenge. There has been great progress on this (eg. see PLOOKUP), but we still need more, especially if we want to encode general-purpose virtual machine execution into polynomials.
Incrementally verifiable computation: it would be nice to be able to efficiently keep "extending" a proof while a computation continues. This is valuable in the "single-prover" case, but also in the "multi-prover" case, particularly a blockchain where a different participant creates each block. See Halo for some recent work on this.