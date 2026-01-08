#!/usr/bin/env python3
"""
High-Performance Data Analysis Pipeline
Monte Carlo Simulation for Option Pricing (Black-Scholes)
"""

import numpy as np
import pandas as pd
from scipy import stats
import time
import os
from datetime import datetime

# Configuration
SIMULATIONS = 10_000_000  # 10 million simulations for HPC demonstration
TIME_STEPS = 252  # Trading days in a year
OUTPUT_DIR = "/app/output"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "analysis_results.csv")

def monte_carlo_option_pricing(
    S0=100.0,      # Initial stock price
    K=105.0,       # Strike price
    T=1.0,         # Time to maturity (years)
    r=0.05,        # Risk-free rate
    sigma=0.2,     # Volatility
    n_sims=SIMULATIONS,
    n_steps=TIME_STEPS
):
    """
    Monte Carlo simulation for European call option pricing using Black-Scholes model.
    
    This computation-intensive task demonstrates:
    - Large-scale random number generation
    - Vectorized operations on millions of data points
    - Statistical analysis at scale
    """
    print(f"Starting Monte Carlo simulation with {n_sims:,} paths...")
    start_time = time.time()
    
    # Time increment
    dt = T / n_steps
    
    # Generate random walks for stock prices
    # Shape: (n_steps, n_sims)
    Z = np.random.standard_normal((n_steps, n_sims))
    
    # Calculate cumulative returns using geometric Brownian motion
    # S(t) = S0 * exp((r - 0.5*sigma^2)*t + sigma*sqrt(dt)*Z)
    drift = (r - 0.5 * sigma**2) * dt
    diffusion = sigma * np.sqrt(dt) * Z
    
    # Cumulative sum along time axis
    price_paths = S0 * np.exp(np.cumsum(drift + diffusion, axis=0))
    
    # Terminal stock prices
    ST = price_paths[-1, :]
    
    # Calculate payoffs for European call option
    payoffs = np.maximum(ST - K, 0)
    
    # Discount payoffs to present value
    option_price = np.exp(-r * T) * np.mean(payoffs)
    
    # Calculate statistics
    std_error = np.std(payoffs) / np.sqrt(n_sims)
    confidence_interval = 1.96 * std_error
    
    elapsed_time = time.time() - start_time
    print(f"Simulation completed in {elapsed_time:.2f} seconds")
    
    return {
        'option_price': option_price,
        'std_error': std_error,
        'confidence_interval_95': confidence_interval,
        'elapsed_time': elapsed_time,
        'simulations': n_sims,
        'terminal_prices': ST
    }

def matrix_computation_benchmark():
    """
    Additional computational benchmark: Large matrix operations
    Tests linear algebra performance on AMD EPYC hardware
    """
    print("\nRunning matrix computation benchmark...")
    start_time = time.time()
    
    # Generate large random matrices
    size = 5000
    A = np.random.randn(size, size)
    B = np.random.randn(size, size)
    
    # Matrix multiplication (O(n^3) complexity)
    C = np.dot(A, B)
    
    # Eigenvalue computation (computational intensive)
    eigenvalues = np.linalg.eigvals(C[:1000, :1000])  # Subset for reasonable time
    
    elapsed_time = time.time() - start_time
    print(f"Matrix benchmark completed in {elapsed_time:.2f} seconds")
    
    return {
        'matrix_size': size,
        'elapsed_time': elapsed_time,
        'max_eigenvalue': np.max(np.abs(eigenvalues))
    }

def main():
    """
    Main execution pipeline
    """
    print("="*70)
    print("CAROLINA CLOUD HPC DATA ANALYSIS PIPELINE")
    print("="*70)
    print(f"Start Time: {datetime.now().isoformat()}")
    print(f"Output Directory: {OUTPUT_DIR}")
    print("="*70)
    
    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Run Monte Carlo simulation
    mc_results = monte_carlo_option_pricing()
    
    # Run matrix benchmark
    matrix_results = matrix_computation_benchmark()
    
    # Analytical Black-Scholes price for comparison
    S0, K, T, r, sigma = 100.0, 105.0, 1.0, 0.05, 0.2
    d1 = (np.log(S0/K) + (r + 0.5*sigma**2)*T) / (sigma*np.sqrt(T))
    d2 = d1 - sigma*np.sqrt(T)
    analytical_price = S0*stats.norm.cdf(d1) - K*np.exp(-r*T)*stats.norm.cdf(d2)
    
    # Calculate pricing error
    pricing_error = abs(mc_results['option_price'] - analytical_price)
    error_percentage = (pricing_error / analytical_price) * 100
    
    # Prepare summary results
    results_summary = pd.DataFrame([{
        'timestamp': datetime.now().isoformat(),
        'monte_carlo_simulations': mc_results['simulations'],
        'mc_option_price': mc_results['option_price'],
        'mc_std_error': mc_results['std_error'],
        'mc_ci_95': mc_results['confidence_interval_95'],
        'mc_elapsed_time_sec': mc_results['elapsed_time'],
        'analytical_bs_price': analytical_price,
        'pricing_error': pricing_error,
        'error_percentage': error_percentage,
        'matrix_computation_size': matrix_results['matrix_size'],
        'matrix_elapsed_time_sec': matrix_results['elapsed_time'],
        'matrix_max_eigenvalue': matrix_results['max_eigenvalue'],
        'total_elapsed_time_sec': mc_results['elapsed_time'] + matrix_results['elapsed_time']
    }])
    
    # Terminal price distribution statistics
    terminal_stats = pd.DataFrame([{
        'metric': 'Terminal Stock Price Distribution',
        'mean': np.mean(mc_results['terminal_prices']),
        'median': np.median(mc_results['terminal_prices']),
        'std': np.std(mc_results['terminal_prices']),
        'min': np.min(mc_results['terminal_prices']),
        'max': np.max(mc_results['terminal_prices']),
        'percentile_25': np.percentile(mc_results['terminal_prices'], 25),
        'percentile_75': np.percentile(mc_results['terminal_prices'], 75),
        'percentile_95': np.percentile(mc_results['terminal_prices'], 95)
    }])
    
    # Save results to CSV
    results_summary.to_csv(OUTPUT_FILE, index=False)
    terminal_stats.to_csv(
        os.path.join(OUTPUT_DIR, "terminal_price_stats.csv"),
        index=False
    )
    
    # Print summary
    print("\n" + "="*70)
    print("RESULTS SUMMARY")
    print("="*70)
    print(f"Monte Carlo Option Price: ${mc_results['option_price']:.4f}")
    print(f"Analytical BS Price:      ${analytical_price:.4f}")
    print(f"Pricing Error:            ${pricing_error:.4f} ({error_percentage:.2f}%)")
    print(f"95% Confidence Interval:  ±${mc_results['confidence_interval_95']:.4f}")
    print(f"MC Computation Time:      {mc_results['elapsed_time']:.2f} seconds")
    print(f"Matrix Computation Time:  {matrix_results['elapsed_time']:.2f} seconds")
    print("="*70)
    print(f"Results saved to: {OUTPUT_FILE}")
    print(f"End Time: {datetime.now().isoformat()}")
    print("="*70)

if __name__ == "__main__":
    main()

