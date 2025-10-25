---
title: "Flow Matching 笔记"
date: 2025-10-24
tags: [flow-matching, diffusion, generative-models]
---

# Flow Matching 笔记

**日期**：2025-10-24  
**主题**：Flow matching 的目标 / 训练目标与数值采样权衡 / 实践要点

## 前置知识

**通量与散度**

- 通量是单位时间内通过某个曲面的量 $\iint_{\Sigma} \vec{A} \cdot \vec{n} d S$

- 散度：可用于表征空间各点矢量场发散的强弱程度（在通量的基础上去做一个极限）

  $\operatorname{div} \vec{A}(M)=\lim _{\Omega \rightarrow M} \frac{1}{V} \oiint_{\Sigma} \vec{A} \cdot \vec{n} d S$

  $\operatorname{div} \mathbf{F}=\nabla \cdot \mathbf{F}=\frac{\partial F_{x}}{\partial x}+\frac{\partial F_{y}}{\partial y}+\frac{\partial F_{z}}{\partial z} \operatorname{div}=\sum_{i=1}^{d} \frac{\partial}{\partial x^{i}}$ (对函数的变量求偏导再做一个累加)

**概率密度函数的变量变换**  $z\sim \pi(z)$  $f : x=f(z) \quad z = f^{-1}(x)$

$p(x)=\pi(z)\left|\frac{d z}{d x}\right|=\pi\left(f^{-1}(x)\right)\left|\frac{d f^{-1}}{d x}\right|=\pi\left(f^{-1}(x)\right)\left|\left(f^{-1}\right)^{\prime}(x)\right|$

DDPM: $X_t = \sqrt{\bar{\alpha} }x_0 + \sqrt{1-\bar{\alpha} }\varepsilon\sim N(0,1) $

$p(x_t)\sim N(\sqrt{\bar{\alpha_t} }x_0, 1-\bar{\alpha_t} 1)$

$x_t= f(\varepsilon) \quad \varepsilon=f^{-1}(x_t) $



**flow的基本概念**

建模了两个分布之间的联系

![image-20251024162955682](C:\Users\admin\my-notes\notes\assets\image-20251024162955682.png)

$\underline{X}_{t}=(\underbrace{f_{t} \circ f_{t-1} \circ \cdots \cdot f_{1}}_{\phi_{t} / \psi_{t}})(\left.x_{0}\right)$    将$x_0$的分布转到$x_t$的分布

将t进行归一化，变成了0到1之间，并且认识它是连续的



**Continuous normalizing flows (ODE)**

$\begin{aligned}
\frac{d}{d t} \phi_{t}(x) & =v_{t}\left(\phi_{t}(x)\right) \\
\phi_{0}(x) & =x
\end{aligned}$   通过欧拉方法采样我们的图像

Flow、time-dependent vector field、 probability density path

![image-20251024165104694](C:\Users\admin\my-notes\notes\assets\image-20251024165104694.png)

**Push**-forward Equation

$p_{t}=\left[\phi_{t}\right]_{*} p_{0}=P_{0}\left(\phi_{t}^{-1}(x)\right)\left|\left(\phi^{-1}\right)^{\prime}(x)\right|$  用$\phi_{t}$表示两个分布之间的关系（将初始分布变成t时刻的分布）

**Continuity** Equation

确保一个向量场$v_t$（箭头）可生成概率路径$p_t$

$\frac{d}{d t} p_{t}(x)+\operatorname{div}\left(p_{t}(x) v_{t}(x)\right)=0$









## 摘要

Flow Matching 的目标是学习一个时间依赖速度场 \(v_\theta(x,t)\)，使得 ODE
\[
\frac{dx}{dt} = v_\theta(x,t)
\]
能够把源分布 \(\mu\) 推送到目标分布 \(\nu\)。训练通过匹配在时间点 \(t\) 上的条件速度（或等价的位移）来实现“点到点”的流形传输，从而把分布变换问题转化为回归速度场的问题。

## 核心概念（简要）
- **粒子轨迹**：给定 \(x_0\sim\mu\)、目标样本 \(x_1\sim\nu\)，可构造某种中间插值 \(x_t\)（例如线性插值 \(x_t=(1-t)x_0 + t x_1\)），并定义对应的目标速度/位移作为训练监督。  
- **目标**：学习 \(v_\theta\) 使得求解 ODE 从 \(t=0\) 到 \(t=1\) 后，粒子从 \(\mu\) 分布移动到 \(\nu\) 分布。  
- **Flow-matching loss（直观形式）**：
\[
\mathcal{L}(\theta)=\mathbb{E}_{t\sim U(0,1),\,x_0\sim\mu,\,x_1\sim\nu}\Big[\big\|v_\theta(x_t,t)-v^\star(x_0,x_1,t)\big\|^2\Big],
\]
其中 \(x_t\) 是按选定耦合/插值生成的中间点，\(v^\star\) 是由 \(x_0,x_1,t\) 明确给出的目标速度（例如线性插值下 \(v^\star = x_1-x_0\) 的某种缩放）。（不同论文有不同的具体公式与缩放项。）

## 为什么“轨迹尽量直”重要（直觉）
- 数值积分（如 Euler）对曲率敏感：轨迹二阶导越大，离散化误差越显著，需要更多步数或高阶求积器。  
- 若轨迹近似直线，Euler 用少量步就能逼近连续流，从而实现 **快速采样 + 高精度** 的两全其美。  
- 在最优传输（W2）意义下，Benamou–Brenier 动态解产生的位移插值是“最小动能”的轨迹，往往是直线型（相对于各粒子的一对一映射）。

## 实践要点与建议
- **选择耦合/插值策略**：线性插值易于实现（直接给出 \(v^\star\)），但并不总是最优。可尝试先估计单步 Monge map \(T\)，再用线性插值减少曲率。  
- **正则化**：
  - 动能正则化 \(\int \|v\|^2\) 鼓励低速解（更平滑路径）。  
  - 曲率惩罚 \(\int \|\partial_t v + (v\cdot\nabla)v\|^2\) 直接约束轨迹加速度（实验上可小系数尝试）。  
- **数值方案**：
  - 训练时用中等细分步长采样轨迹来估计损失；采样时可使用较少步长但配合训练得到的“较直”速度场。  
  - 若轨迹仍然弯曲，可考虑 RK4 或自适应步长求解器以减少步数带来的误差。  
- **架构与条件化**：速度场通常做成 UNet/ResNet 风格（图像任务）并条件化时间 \(t\)。可探索时间分离参数化 \(v(x,t)=\alpha(t)w(x)\) 来限制表达并促使方向性一致。  
- **监控指标**：采样质量用 FID/IS，逼近性可用样本匹配、Wasserstein 距离估计，轨迹曲率可用 \(\mathbb{E}\|\ddot x(t)\|\) 之类的统计量。

## 常见超参 / 实验建议
- 初始尝试：时间步 \(N=10\)–\(50\)；学习率 \(1e-4\)；动能正则化系数 \(\lambda_1\) 从 \(1e-4\) 试起；曲率惩罚 \(\lambda_2\) 从 \(1e-6\) 起。  
- 若采样慢但质量好，尝试增大 \(\lambda_1\)/\(\lambda_2\) 以鼓励更直轨迹并减少采样步数。  
- 对比实验：baseline（无正则） vs +动能正则 vs +加速度惩罚，比较步数-质量曲线（step vs FID）。

## 参考 / 延伸阅读
- Benamou, J.-D. & Brenier, Y., _A computational fluid mechanics solution to the Monge–Kantorovich mass transfer problem_, 2000.  
- Flow matching / Rectified Flow 相关论文（查阅最近几年 diffusion / flow-matching 论文以获取详细公式和实现细节）。  
- 实验笔记：记录训练曲线、采样步数与 FID 的关系，为调参提供依据。

## TODO
- 把上面建议的超参做成对照表并跑小规模实验（MNIST / CIFAR-10）记录 step-vs-FID。  
- 尝试估计 Monge 映射 \(T\) 并用线性插值做基准比较。  
- 实现并测量 \(\|\ddot x\|\) 的统计量，作为轨迹“曲率”度量。

