"""
Utility functions and helpers for Edge AI Copilot.
"""
import logging
import sys
from datetime import datetime
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path


def setup_logging(log_dir: str, retention_days: int) -> logging.Logger:
    """
    Configure logging with daily rotation and retention policy.
    
    Args:
        log_dir: Directory to store log files
        retention_days: Number of days to retain logs
        
    Returns:
        Configured logger instance
    """
    # Create log directory if it doesn't exist
    log_path = Path(log_dir)
    log_path.mkdir(parents=True, exist_ok=True)
    
    # Generate log filename with current date
    log_filename = log_path / f"edge_ai_{datetime.now().strftime('%Y%m%d')}.log"
    
    # Create root logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Remove existing handlers
    logger.handlers.clear()
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(name)-20s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Create rotating file handler (daily rotation)
    file_handler = TimedRotatingFileHandler(
        filename=log_filename,
        when='midnight',
        interval=1,
        backupCount=retention_days,
        encoding='utf-8'
    )
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    
    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    logger.info("=" * 80)
    logger.info("Edge AI Copilot - Logging initialized")
    logger.info(f"Log directory: {log_dir}")
    logger.info(f"Retention: {retention_days} days")
    logger.info("=" * 80)
    
    return logger


def log_telemetry(logger: logging.Logger, telemetry) -> None:
    """
    Log received telemetry data.
    
    Args:
        logger: Logger instance
        telemetry: TelemetryData instance
    """
    logger.info(
        f"Telemetry received - "
        f"timestamp: {telemetry.timestamp}, "
        f"soldier: ({telemetry.soldier['x']:.1f}, {telemetry.soldier['y']:.1f}), "
        f"enemy: ({telemetry.enemy['x']:.1f}, {telemetry.enemy['y']:.1f}), "
        f"hostage: ({telemetry.hostage['x']:.1f}, {telemetry.hostage['y']:.1f}), "
        f"environment: {telemetry.environment}, "
        f"threat_level: {telemetry.threat_level}"
    )


def log_decision(logger: logging.Logger, decision: str, risk_score: float, 
                latency_ms: int) -> None:
    """
    Log tactical decision with metrics.
    
    Args:
        logger: Logger instance
        decision: Tactical decision text
        risk_score: Computed risk score
        latency_ms: Processing latency in milliseconds
    """
    logger.info(
        f"Decision generated - "
        f"text: '{decision}', "
        f"risk_score: {risk_score:.2f}, "
        f"latency: {latency_ms}ms"
    )


def log_error(logger: logging.Logger, error_type: str, error: Exception) -> None:
    """
    Log error with stack trace.
    
    Args:
        logger: Logger instance
        error_type: Type/category of error
        error: Exception instance
    """
    logger.error(
        f"Error occurred - type: {error_type}, message: {str(error)}",
        exc_info=True
    )
